// Tests for ../firestore.rules (CLAUDE.md privacy rules), using the local
// Firestore emulator. Run from this folder:  npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc,
  updateDoc, where, writeBatch,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sonus',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  // Starting data, written with rules switched off.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/amaya'), {
      role: 'therapist', name: 'Dr. Amaya Silva', email: 'amaya@x.com',
      code: 'SN-1111', inviteCode: 'K7MPQ4',
    });
    await setDoc(doc(db, 'inviteCodes/K7MPQ4'), { therapistId: 'amaya' });
    await setDoc(doc(db, 'users/other'), {
      role: 'therapist', name: 'Dr. Other', email: 'other@x.com',
      code: 'SN-2222', inviteCode: 'ZZZZZZ',
    });
    await setDoc(doc(db, 'inviteCodes/ZZZZZZ'), { therapistId: 'other' });
    await setDoc(doc(db, 'users/nimali'), {
      role: 'user', name: 'Nimali Perera', email: 'nimali@x.com', code: 'SN-2048',
      therapistId: 'amaya', linkedCode: 'K7MPQ4',
    });
    await setDoc(doc(db, 'users/kasun'), {
      role: 'user', name: 'Kasun J', email: 'kasun@x.com', code: 'SN-1984',
    });
    await setDoc(doc(db, 'exercises/mala'), {
      therapistId: 'amaya', text: 'මල', expectedPhonemes: ['m', 'a', 'l', 'ə'],
      g2pVersion: 'inv-v1.1+app', createdAt: new Date(),
    });
    await setDoc(doc(db, 'exercises/gasa'), {
      therapistId: 'other', text: 'ගස', expectedPhonemes: ['ɡ', 'a', 's', 'ə'],
      g2pVersion: 'inv-v1.1+app', createdAt: new Date(),
    });
    await setDoc(doc(db, 'assignments/nimali_mala'), {
      therapistId: 'amaya', userId: 'nimali', exerciseId: 'mala',
      text: 'මල', expectedPhonemes: ['m', 'a', 'l', 'ə'], createdAt: new Date(),
    });
    await setDoc(doc(db, 'attempts/a1'), { ...attempt(), createdAt: new Date() });
  });
});

/** Firestore as a signed-in person (or signed out when uid is null). */
function as(uid, email = `${uid}@x.com`) {
  return uid
    ? env.authenticatedContext(uid, { email }).firestore()
    : env.unauthenticatedContext().firestore();
}

describe('users: reading', () => {
  it('a user reads their own profile', async () => {
    await assertSucceeds(getDoc(doc(as('kasun'), 'users/kasun')));
  });

  it('a user cannot read another user', async () => {
    await assertFails(getDoc(doc(as('kasun'), 'users/nimali')));
  });

  it('signed out cannot read anything', async () => {
    await assertFails(getDoc(doc(as(null), 'users/nimali')));
  });

  it('a therapist reads an assigned user', async () => {
    await assertSucceeds(getDoc(doc(as('amaya'), 'users/nimali')));
  });

  it('a therapist cannot read a user who is not assigned to them', async () => {
    await assertFails(getDoc(doc(as('amaya'), 'users/kasun')));
    await assertFails(getDoc(doc(as('other'), 'users/nimali')));
  });

  it('a user reads their own therapist', async () => {
    await assertSucceeds(getDoc(doc(as('nimali'), 'users/amaya')));
    await assertFails(getDoc(doc(as('nimali'), 'users/other')));
  });

  it('a therapist can list only their assigned users', async () => {
    const db = as('amaya');
    await assertSucceeds(getDocs(query(collection(db, 'users'), where('therapistId', '==', 'amaya'))));
    await assertFails(getDocs(collection(db, 'users')));
  });
});

describe('users: sign-up', () => {
  it('creates your own user profile', async () => {
    await assertSucceeds(setDoc(doc(as('new', 'new@x.com'), 'users/new'), {
      role: 'user', name: 'New', email: 'new@x.com', code: 'SN-3333',
    }));
  });

  it('cannot create a profile for someone else', async () => {
    await assertFails(setDoc(doc(as('new', 'new@x.com'), 'users/someone'), {
      role: 'user', name: 'New', email: 'new@x.com', code: 'SN-3333',
    }));
  });

  it('cannot pick a made-up role or link a therapist at sign-up', async () => {
    const db = as('new', 'new@x.com');
    await assertFails(setDoc(doc(db, 'users/new'), {
      role: 'admin', name: 'New', email: 'new@x.com', code: 'SN-3333',
    }));
    await assertFails(setDoc(doc(db, 'users/new'), {
      role: 'user', name: 'New', email: 'new@x.com', code: 'SN-3333', therapistId: 'amaya',
    }));
  });

  it('a therapist creates profile + invite code in one batch', async () => {
    const db = as('t2', 't2@x.com');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/t2'), {
      role: 'therapist', name: 'Dr. T', email: 't2@x.com', code: 'SN-4444', inviteCode: 'ABCDEF',
    });
    batch.set(doc(db, 'inviteCodes/ABCDEF'), { therapistId: 't2' });
    await assertSucceeds(batch.commit());
  });

  it('a user cannot create an invite code', async () => {
    await assertFails(setDoc(doc(as('kasun'), 'inviteCodes/QWERTY'), { therapistId: 'kasun' }));
  });

  it('nobody can take over an existing invite code', async () => {
    const db = as('t2', 't2@x.com');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/t2'), {
      role: 'therapist', name: 'Dr. T', email: 't2@x.com', code: 'SN-4444', inviteCode: 'K7MPQ4',
    });
    batch.set(doc(db, 'inviteCodes/K7MPQ4'), { therapistId: 't2' });
    await assertFails(batch.commit());
  });
});

describe('users: updates', () => {
  it('a user links to a therapist with a valid code', async () => {
    await assertSucceeds(updateDoc(doc(as('kasun'), 'users/kasun'), {
      therapistId: 'amaya', linkedCode: 'K7MPQ4', linkedAt: serverTimestamp(),
    }));
  });

  it('linkedAt must be the server time', async () => {
    await assertFails(updateDoc(doc(as('kasun'), 'users/kasun'), {
      therapistId: 'amaya', linkedCode: 'K7MPQ4', linkedAt: new Date(2020, 0, 1),
    }));
  });

  it('a name cannot be empty', async () => {
    await assertFails(updateDoc(doc(as('kasun'), 'users/kasun'), { name: '' }));
  });

  it('a user cannot link with a code that belongs to someone else', async () => {
    await assertFails(updateDoc(doc(as('kasun'), 'users/kasun'), {
      therapistId: 'amaya', linkedCode: 'ZZZZZZ',
    }));
  });

  it('a user cannot link without a code', async () => {
    await assertFails(updateDoc(doc(as('kasun'), 'users/kasun'), { therapistId: 'amaya' }));
  });

  it('nobody can change their own role', async () => {
    await assertFails(updateDoc(doc(as('kasun'), 'users/kasun'), { role: 'therapist' }));
  });

  it('you can change your name, but not someone else\'s', async () => {
    await assertSucceeds(updateDoc(doc(as('kasun'), 'users/kasun'), { name: 'Kasun J.' }));
    await assertFails(updateDoc(doc(as('amaya'), 'users/nimali'), { name: 'Changed' }));
  });

  it('nobody can list invite codes', async () => {
    await assertSucceeds(getDoc(doc(as('kasun'), 'inviteCodes/K7MPQ4')));
    await assertFails(getDocs(collection(as('kasun'), 'inviteCodes')));
  });
});

/** A new exercise as the app writes it. */
function newExercise(therapistId, extra = {}) {
  return {
    therapistId, text: 'කමල', romanized: 'kamala',
    expectedPhonemes: ['k', 'a', 'm', 'a', 'l', 'ə'],
    g2pVersion: 'inv-v1.1+app', createdAt: serverTimestamp(), ...extra,
  };
}

/** A new assignment of exercises/mala as the app writes it. */
function newAssignment(userId, extra = {}) {
  return {
    therapistId: 'amaya', userId, exerciseId: 'mala',
    text: 'මල', expectedPhonemes: ['m', 'a', 'l', 'ə'],
    createdAt: serverTimestamp(), ...extra,
  };
}

describe('exercises', () => {
  it('a therapist creates an exercise', async () => {
    await assertSucceeds(setDoc(doc(as('amaya'), 'exercises/new'), newExercise('amaya')));
  });

  it('an adult user cannot create an exercise', async () => {
    await assertFails(setDoc(doc(as('kasun'), 'exercises/new'), newExercise('kasun')));
  });

  it('a therapist cannot create an exercise in another name', async () => {
    await assertFails(setDoc(doc(as('amaya'), 'exercises/new'), newExercise('other')));
  });

  it('an exercise needs text and phonemes, and nothing extra', async () => {
    const db = as('amaya');
    await assertFails(setDoc(doc(db, 'exercises/new'), newExercise('amaya', { text: '' })));
    await assertFails(setDoc(doc(db, 'exercises/new'), newExercise('amaya', { expectedPhonemes: [] })));
    await assertFails(setDoc(doc(db, 'exercises/new'), newExercise('amaya', { extra: 1 })));
  });

  it('a therapist reads and lists only their own exercises', async () => {
    const db = as('amaya');
    await assertSucceeds(getDoc(doc(db, 'exercises/mala')));
    await assertFails(getDoc(doc(db, 'exercises/gasa')));
    await assertSucceeds(getDocs(query(collection(db, 'exercises'), where('therapistId', '==', 'amaya'))));
    await assertFails(getDocs(collection(db, 'exercises')));
  });

  it('users cannot read the exercise library', async () => {
    await assertFails(getDoc(doc(as('nimali'), 'exercises/mala')));
  });

  it('exercises are never edited; only the owner deletes', async () => {
    await assertFails(updateDoc(doc(as('amaya'), 'exercises/mala'), { text: 'ගස' }));
    await assertFails(deleteDoc(doc(as('other'), 'exercises/mala')));
    await assertSucceeds(deleteDoc(doc(as('amaya'), 'exercises/mala')));
  });
});

describe('assignments', () => {
  it('a therapist assigns their exercise to a linked user', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'users/kasun'), { therapistId: 'amaya' });
    });
    await assertSucceeds(setDoc(doc(as('amaya'), 'assignments/kasun_mala'), newAssignment('kasun')));
  });

  it('cannot assign to a user who is not linked to you', async () => {
    await assertFails(setDoc(doc(as('amaya'), 'assignments/kasun_mala'), newAssignment('kasun')));
  });

  it('cannot assign an exercise of another therapist', async () => {
    await assertFails(setDoc(doc(as('amaya'), 'assignments/nimali_gasa'), newAssignment('nimali', {
      exerciseId: 'gasa', text: 'ගස', expectedPhonemes: ['ɡ', 'a', 's', 'ə'],
    })));
  });

  it('the ID and the copy must match the exercise', async () => {
    await assertFails(setDoc(doc(as('amaya'), 'assignments/nimali_mala2'), newAssignment('nimali')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await deleteDoc(doc(ctx.firestore(), 'assignments/nimali_mala'));
    });
    await assertFails(setDoc(doc(as('amaya'), 'assignments/nimali_mala'),
      newAssignment('nimali', { text: 'ගස' })));
    await assertSucceeds(setDoc(doc(as('amaya'), 'assignments/nimali_mala'), newAssignment('nimali')));
  });

  it('an adult user cannot assign exercises', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'assignments/nimali_mala'), newAssignment('nimali', {
      therapistId: 'nimali',
    })));
  });

  it('the user and their therapist read it; nobody else', async () => {
    await assertSucceeds(getDoc(doc(as('nimali'), 'assignments/nimali_mala')));
    await assertSucceeds(getDoc(doc(as('amaya'), 'assignments/nimali_mala')));
    await assertFails(getDoc(doc(as('kasun'), 'assignments/nimali_mala')));
    await assertFails(getDoc(doc(as('other'), 'assignments/nimali_mala')));
  });

  it('list queries must be limited to your own assignments', async () => {
    await assertSucceeds(getDocs(query(collection(as('nimali'), 'assignments'), where('userId', '==', 'nimali'))));
    await assertSucceeds(getDocs(query(collection(as('amaya'), 'assignments'),
      where('therapistId', '==', 'amaya'), where('userId', '==', 'nimali'))));
    await assertFails(getDocs(query(collection(as('amaya'), 'assignments'), where('userId', '==', 'nimali'))));
    await assertFails(getDocs(collection(as('kasun'), 'assignments')));
  });

  it('only the therapist removes an assignment; nobody edits it', async () => {
    await assertFails(updateDoc(doc(as('amaya'), 'assignments/nimali_mala'), { text: 'ගස' }));
    await assertFails(deleteDoc(doc(as('nimali'), 'assignments/nimali_mala')));
    await assertSucceeds(deleteDoc(doc(as('amaya'), 'assignments/nimali_mala')));
  });
});

// ---------------------------------------------------------------- attempts

/** A valid attempt by Nimali at මල (assigned by Amaya). */
function attempt(changes = {}) {
  return {
    userId: 'nimali', therapistId: 'amaya', exerciseId: 'mala',
    sessionId: 's1', text: 'මල', recordingMs: 840,
    createdAt: serverTimestamp(),
    result: {
      quality: { ok: true, reason: null, duration_s: 0.84 },
      expected: ['m', 'a', 'l', 'ə'], predicted: ['m', 'a', 'r', 'ə'],
      ops: [
        { op: 'match', expected: 'm', predicted: 'm', position: 0 },
        { op: 'match', expected: 'a', predicted: 'a', position: 1 },
        { op: 'sub', expected: 'l', predicted: 'r', position: 2 },
        { op: 'match', expected: 'ə', predicted: 'ə', position: 3 },
      ],
      match_percent: 75.0,
      model_version: 'mms300m-L12-bilstm-ctc', g2p_version: 'inv-v1.1+cff96fb2',
    },
    ...changes,
  };
}

describe('attempts: saving', () => {
  it('a linked user saves an attempt at an assigned word', async () => {
    await assertSucceeds(setDoc(doc(as('nimali'), 'attempts/new'), attempt()));
  });

  it('an empty text never counts as assigned', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'),
      attempt({ exerciseId: 'not-assigned', text: '' })));
  });

  it('the text must be the assigned text', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), attempt({ text: 'ගස' })));
  });

  it('only for an exercise assigned to them', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'),
      attempt({ exerciseId: 'gasa', text: 'ගස' })));
  });

  it('therapistId must be their current therapist', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), attempt({ therapistId: 'other' })));
  });

  it('nobody saves an attempt for someone else', async () => {
    await assertFails(setDoc(doc(as('kasun'), 'attempts/new'), attempt()));
    await assertFails(setDoc(doc(as('amaya'), 'attempts/new'), attempt()));
  });

  it('the time is the server time', async () => {
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), attempt({ createdAt: new Date(0) })));
  });

  it('the result must have the service shape', async () => {
    const bad = attempt();
    bad.result.match_percent = 150;
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), bad));
    const extra = attempt();
    extra.result.diagnosis = 'x';
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), extra));
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), attempt({ audio: 'x' })));
  });

  it('the automated result is write-once', async () => {
    await assertFails(updateDoc(doc(as('nimali'), 'attempts/a1'), { 'result.match_percent': 100 }));
    await assertFails(updateDoc(doc(as('amaya'), 'attempts/a1'), { 'result.match_percent': 100 }));
    await assertFails(setDoc(doc(as('nimali'), 'attempts/a1'), attempt()));
    await assertFails(deleteDoc(doc(as('nimali'), 'attempts/a1')));
    await assertFails(deleteDoc(doc(as('amaya'), 'attempts/a1')));
  });
});

describe('attempts: self-practice (starter words)', () => {
  const starter = (changes = {}) => attempt({ exerciseId: 'starter-w003', text: 'බර', ...changes });

  it('a linked user saves a starter word without an assignment', async () => {
    await assertSucceeds(setDoc(doc(as('nimali'), 'attempts/new'), starter()));
  });

  it('a user without a therapist saves it with therapistId null', async () => {
    await assertSucceeds(setDoc(doc(as('kasun'), 'attempts/new'),
      starter({ userId: 'kasun', therapistId: null })));
  });

  it('...but cannot send it to a therapist they are not linked to', async () => {
    await assertFails(setDoc(doc(as('kasun'), 'attempts/new'),
      starter({ userId: 'kasun', therapistId: 'amaya' })));
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), starter({ therapistId: null })));
  });

  it('only real starter ids, and a short text', async () => {
    for (const exerciseId of ['starter-', 'starter-x01', 'starter-w0001', 'w003', 'gasa']) {
      await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), starter({ exerciseId })));
    }
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), starter({ text: '' })));
    await assertFails(setDoc(doc(as('nimali'), 'attempts/new'), starter({ text: 'බ'.repeat(41) })));
  });

  it('the linked therapist reads it; nobody else does', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'attempts/self'), { ...starter(), createdAt: new Date() });
      await setDoc(doc(ctx.firestore(), 'attempts/private'),
        { ...starter({ userId: 'kasun', therapistId: null }), createdAt: new Date() });
    });
    await assertSucceeds(getDoc(doc(as('amaya'), 'attempts/self')));
    await assertFails(getDoc(doc(as('other'), 'attempts/self')));
    await assertSucceeds(getDoc(doc(as('kasun'), 'attempts/private')));
    await assertFails(getDoc(doc(as('amaya'), 'attempts/private')));
    await assertFails(getDoc(doc(as('other'), 'attempts/private')));
  });
});

describe('attempts: reading', () => {
  it('the user reads their own attempts', async () => {
    const db = as('nimali');
    await assertSucceeds(getDoc(doc(db, 'attempts/a1')));
    await assertSucceeds(getDocs(query(collection(db, 'attempts'), where('userId', '==', 'nimali'))));
  });

  it('another user cannot', async () => {
    const db = as('kasun');
    await assertFails(getDoc(doc(db, 'attempts/a1')));
    await assertFails(getDocs(query(collection(db, 'attempts'), where('userId', '==', 'nimali'))));
  });

  it("the user's therapist reads them, another therapist cannot", async () => {
    await assertSucceeds(getDoc(doc(as('amaya'), 'attempts/a1')));
    // One user at a time: the rules check that user is still linked.
    await assertSucceeds(getDocs(query(collection(as('amaya'), 'attempts'),
      where('therapistId', '==', 'amaya'), where('userId', '==', 'nimali'))));
    await assertFails(getDoc(doc(as('other'), 'attempts/a1')));
    await assertFails(getDocs(query(collection(as('other'), 'attempts'),
      where('therapistId', '==', 'amaya'), where('userId', '==', 'nimali'))));
    await assertFails(getDocs(query(collection(as('other'), 'attempts'),
      where('userId', '==', 'nimali'))));
  });

  it('after the user links another therapist, the old one cannot read', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'users/nimali'), { therapistId: 'other' }));
    await assertFails(getDoc(doc(as('amaya'), 'attempts/a1')));
  });
});
