import { useState } from "react";
import "./App.css";

import { useToast } from "./hooks/useToast";
import { dict, type Lang } from "./types/constants.types";

import { useUsers } from "./hooks/useUsers";
import { copyToClipboard, maskLink } from "./services/userSecurity";

export default function App() {
  const [lang, setLang] = useState<Lang>(
    () => (localStorage.getItem("lang") as Lang) || "ru",
  );

  const t = dict[lang];

  const switchLang = () => {
    setLang((prev) => {
      const next = prev === "ru" ? "eu" : "ru";
      localStorage.setItem("lang", next);
      return next;
    });
  };

  const [auth, setAuth] = useState(false);
  const [password, setPassword] = useState(
    () => localStorage.getItem("admin_password") || "",
  );

  const login = () => {
    if (!password) return;

    localStorage.setItem("admin_password", password);
    setAuth(true);
    loadUsers();
  };

  const [prefix, setPrefix] = useState("user");
  const [visibleLinks, setVisibleLinks] = useState<Record<string, boolean>>({});

  const toggleLink = (id: string) => {
    setVisibleLinks((p) => ({
      ...p,
      [id]: !p[id],
    }));
  };

  const { toasts, push } = useToast();

  const { users, loading, creating, loadUsers, createUser, deleteUser } =
    useUsers(push, t);

  const copy = (text?: string) => {
    copyToClipboard(text, push, t.copied);
  };

  if (!auth) {
    return (
      <div className="h-screen flex items-center justify-center">
        <div className="panel w-[320px] space-y-3">
          <input
            type="password"
            className="input"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <button className="btn primary w-full" onClick={login}>
            {t.login}
          </button>
        </div>
      </div>
    );
  }

  // ---------------- MAIN UI ----------------
  return (
    <div className="p-6">
      {/* HEADER */}
      <div className="flex justify-between items-center mb-6">
        <div className="text-2xl font-bold">NAIVE PANEL</div>

        <button className="btn" onClick={switchLang}>
          {t.lang}
        </button>
      </div>

      {/* TOASTS */}
      <div className="fixed bottom-4 right-4 space-y-2">
        {toasts.map((toast) => (
          <div key={toast.id} className="panel text-sm">
            {toast.text}
          </div>
        ))}
      </div>

      {/* CREATE USER */}
      <div className="flex gap-2 mb-6">
        <input
          className="input flex-1"
          value={prefix}
          onChange={(e) => setPrefix(e.target.value)}
        />

        <button className="btn primary" onClick={() => createUser(prefix)}>
          {creating ? "..." : t.create}
        </button>
      </div>

      {/* USERS LIST */}
      <div className="space-y-3">
        {loading ? (
          <div>{t.loading}</div>
        ) : (
          users.map((u) => (
            <div key={u.id} className="panel flex justify-between">
              {/* LOGIN */}
              <div>{u.login}</div>

              {/* ACTIONS */}
              <div className="flex gap-2 items-center">
                <div className="text-xs">
                  {visibleLinks[u.id] ? u.link : maskLink(u.link)}
                </div>

                <button className="btn" onClick={() => toggleLink(u.id)}>
                  👁
                </button>

                <button className="btn" onClick={() => copy(u.link)}>
                  {t.copy}
                </button>

                <button className="btn danger" onClick={() => deleteUser(u.id)}>
                  {t.delete}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
