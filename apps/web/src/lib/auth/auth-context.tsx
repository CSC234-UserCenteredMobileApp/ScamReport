import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as fbSignOut,
  type User as FirebaseUser,
} from 'firebase/auth';
import type { AuthUser } from '@my-product/shared';
import { firebaseAuth } from '@/lib/auth/firebase';
import { apiFetch, ApiError } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';

interface AuthState {
  firebaseUser: FirebaseUser | null;
  user: AuthUser | null;
  role: 'user' | 'admin' | null;
  ready: boolean;
  signInWithGoogle: () => Promise<void>;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const unsub = onAuthStateChanged(firebaseAuth, async (fb) => {
      setFirebaseUser(fb);
      if (!fb) {
        setUser(null);
        setReady(true);
        return;
      }
      try {
        const sync = await apiFetch('/auth/sync', validators.authSync, {
          method: 'POST',
          body: {},
        });
        setUser(sync.user);
      } catch (err) {
        if (err instanceof ApiError && err.status === 401) {
          setUser(null);
        } else {
          console.error('[auth] /auth/sync failed', err);
          setUser(null);
        }
      } finally {
        setReady(true);
      }
    });
    return () => unsub();
  }, []);

  const signInWithGoogle = useCallback(async () => {
    await signInWithPopup(firebaseAuth, new GoogleAuthProvider());
  }, []);

  const signInWithEmail = useCallback(async (email: string, password: string) => {
    await signInWithEmailAndPassword(firebaseAuth, email, password);
  }, []);

  const signOut = useCallback(async () => {
    await fbSignOut(firebaseAuth);
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      firebaseUser,
      user,
      role: user?.role ?? null,
      ready,
      signInWithGoogle,
      signInWithEmail,
      signOut,
    }),
    [firebaseUser, user, ready, signInWithGoogle, signInWithEmail, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
