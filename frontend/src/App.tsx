import { useState, useCallback } from "react";

const API = "/api";

type User = {
  id: string;
  login: string;
  password?: string;
  link?: string;
  desktop?: string;
};

const headers = () => ({
  "Content-Type": "application/json",
  "x-admin-password": localStorage.getItem("admin_password") || "",
});

type Toast = {
  id: number;
  text: string;
  type: "success" | "error";
};

function useToast() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const push = useCallback((text: string, type: Toast["type"] = "success") => {
    const id = Date.now();

    setToasts((t) => [...t, { id, text, type }]);

    setTimeout(() => {
      setToasts((t) => t.filter((x) => x.id !== id));
    }, 2500);
  }, []);

  return { toasts, push };
}

export default function App() {
  const [users, setUsers] = useState<User[]>([]);
  const [auth, setAuth] = useState(false);

  const [password, setPassword] = useState(
    () => localStorage.getItem("admin_password") || "",
  );

  const [prefix, setPrefix] = useState("app");
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);

  const { toasts, push } = useToast();

  const loadUsers = useCallback(async () => {
    setLoading(true);

    try {
      const res = await fetch(`${API}/users`, {
        headers: headers(),
      });

      if (res.status === 403) {
        setAuth(false);
        return;
      }

      const data = await res.json();

      setUsers(data.users || []);
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
      await fetch(`${API}/create-user?prefix=${prefix}`, {
        method: "POST",
        headers: headers(),
      });

      push("Пользователь создан", "success");
      await loadUsers();
    } finally {
      setCreating(false);
    }
  };

  const deleteUser = async (id: string) => {
    if (users.length <= 1) {
      push("Нельзя удалить последнего пользователя", "error");
      return;
    }

    await fetch(`${API}/users/${id}`, {
      method: "DELETE",
      headers: headers(),
    });

    push("Удалено", "success");
    await loadUsers();
  };

  const copy = (text?: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    push("Скопировано", "success");
  };

  if (!auth) {
    return (
      <div className="h-screen flex items-center justify-center bg-[#0b0d12] text-white">
        <div className="bg-[#111521] p-6 rounded-xl border border-white/10 w-[320px] space-y-3">
          <div className="text-lg font-semibold">Login</div>

          <input
            type="password"
            className="w-full p-2 rounded-lg bg-black/30 border border-white/10"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <button
            onClick={login}
            className="w-full bg-indigo-500 hover:bg-indigo-600 p-2 rounded-lg"
          >
            login
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0b0d12] text-white p-6">
      {/* toasts */}
      <div className="fixed top-4 right-4 space-y-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`px-3 py-2 rounded-lg text-sm border ${
              t.type === "success"
                ? "bg-green-500/10 border-green-500/30 text-green-300"
                : "bg-red-500/10 border-red-500/30 text-red-300"
            }`}
          >
            {t.text}
          </div>
        ))}
      </div>

      {/* header */}
      <div className="mb-6">
        <div className="text-3xl font-bold">NAIVE PANEL</div>
      </div>

      {/* toolbar */}
      <div className="flex gap-2 mb-6">
        <input
          value={prefix}
          onChange={(e) => setPrefix(e.target.value)}
          className="flex-1 p-2 rounded-lg bg-[#111521] border border-white/10"
        />

        <button
          onClick={createUser}
          disabled={creating}
          className="px-4 rounded-lg bg-indigo-500"
        >
          {creating ? "..." : "create"}
        </button>
      </div>

      {/* list */}
      <div className="space-y-3">
        {loading ? (
          <div className="text-gray-400">loading...</div>
        ) : (
          users.map((u) => (
            <div
              key={u.id}
              className="bg-[#111521] border border-white/10 rounded-xl p-4 grid grid-cols-1 md:grid-cols-4 gap-4"
            >
              <div>{u.login}</div>

              <div className="font-mono text-xs text-blue-300">{u.link}</div>

              <button onClick={() => copy(u.link)}>copy</button>

              <button onClick={() => deleteUser(u.id)}>delete</button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
