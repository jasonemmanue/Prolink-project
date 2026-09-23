import Link from 'next/link';
import Image from 'next/image';

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-prolink-primary to-prolink-secondary p-6">
      <div className="w-full max-w-md card p-8">
        <div className="flex items-center gap-3 mb-6">
          <Image src="/logo.png" alt="ProLink" width={44} height={44} />
          <div>
            <div className="font-display font-extrabold text-2xl text-prolink-primary">ProLink</div>
            <div className="text-xs text-prolink-textSecondary">Panneau d&apos;administration</div>
          </div>
        </div>
        <h1 className="text-xl font-bold mb-4">Connexion</h1>
        <form className="space-y-3">
          <input type="email" placeholder="Email admin" className="w-full bg-prolink-surface border border-prolink-divider px-4 py-3 rounded-xl" />
          <input type="password" placeholder="Mot de passe" className="w-full bg-prolink-surface border border-prolink-divider px-4 py-3 rounded-xl" />
          <input type="text" placeholder="Code OTP 2FA" className="w-full bg-prolink-surface border border-prolink-divider px-4 py-3 rounded-xl" />
          <Link href="/dashboard" className="btn-primary block text-center">Se connecter</Link>
        </form>
        <div className="mt-4 text-xs text-prolink-textSecondary text-center">
          Sécurité : 2FA obligatoire · Journal d&apos;audit actif
        </div>
      </div>
    </div>
  );
}
