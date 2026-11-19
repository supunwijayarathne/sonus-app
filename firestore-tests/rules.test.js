// Tests for ../firestore.rules (CLAUDE.md privacy rules), using the local
// Firestore emulator. Run from this folder:  npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, writeBatch, collection, query, where, getDocs } from 'firebase/firestore';

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
      therapistId: 'amaya', linkedCode: 'K7MPQ4',
    }));
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
