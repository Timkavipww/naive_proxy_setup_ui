import { useCallback, useState } from "react";
import "./App.css";

import { userService } from "./api/userService";
import type { User } from "./types/user";
import { useToast } from "./hooks/useToast";

type Lang = "ru" | "eu";

const dict = {
  ru: {
    login: "Войти",
    create: "Создать",
    delete: "Удалить",
    copy: "Скопировать",
    loading: "загрузка...",
    userCreated: "Пользователь создан",
    copied: "Скопировано",
    cannotDelete: "Нельзя удалить последнего пользователя",
    prefix: "Префикс",
    lang: "RU",
  },
  eu: {
    login: "Login",
    create: "Create",
    delete: "Delete",
    copy: "Copy",
    loading: "loading...",
    userCreated: "User created",
    copied: "Copied",
    cannotDelete: "Cannot delete last user",
    prefix: "Prefix",
    lang: "EU",
  },
};

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

  const [users, setUsers] = useState<User[]>([]);
  const [auth, setAuth] = useState(false);

  const [password, setPassword] = useState(
    () => localStorage.getItem("admin_password") || "",
  );

  const [prefix, setPrefix] = useState("app");
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);

  const [visibleLinks, setVisibleLinks] = useState<Record<string, boolean>>({});

  const { toasts, push } = useToast();

  const loadUsers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await userService.getUsers();
      setUsers(data);
    } finally {
      setLoading(false);
    }
  }, []);

  const login = () => {
    if (!password) return;

    localStorage.setItem("admin_password", password);
    setAuth(true);
    loadUsers();
  };

  const createUser = async () => {
    setCreating(true);
    try {
      await userService.createUser(prefix);

      push(t.userCreated, "success");
      await loadUsers();
    } finally {
      setCreating(false);
    }
  };

  const deleteUser = async (id: string) => {
    if (users.length <= 1) {
      push(t.cannotDelete, "error");
      return;
    }

    await userService.deleteUser(id);

    push(t.delete, "success");
    await loadUsers();
  };

  const copy = (text?: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    push(t.copied, "success");
  };

  const toggleLink = (id: string) => {
    setVisibleLinks((p) => ({ ...p, [id]: !p[id] }));
  };

  const maskLink = (link?: string) => {
    if (!link) return "";
    return link.replace(/:\/\/.*@/, "://***@");
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

  return (
    <div className="p-6">
      {/* header + lang */}
      <div className="flex justify-between items-center mb-6">
        <div className="text-2xl font-bold">NAIVE PANEL</div>

        <button className="btn" onClick={switchLang}>
          {t.lang}
        </button>
      </div>

      {/* toasts */}
      <div className="fixed bottom-4 right-4 space-y-2">
        {toasts.map((t) => (
          <div key={t.id} className="panel text-sm">
            {t.text}
          </div>
        ))}
      </div>

      {/* toolbar */}
      <div className="flex gap-2 mb-6">
        <input
          className="input flex-1"
          value={prefix}
          onChange={(e) => setPrefix(e.target.value)}
          placeholder={t.prefix}
        />

        <button className="btn primary" onClick={createUser}>
          {creating ? "..." : t.create}
        </button>
      </div>

      {/* users */}
      <div className="space-y-3">
        {loading ? (
          <div>{t.loading}</div>
        ) : (
          users.map((u) => (
            <div key={u.id} className="panel flex justify-between">
              <div>{u.login}</div>

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
