import { useEffect, useState } from "react";
import "./App.css";

const API = "/api";

type User = {
  id: string;
  login: string;
  password: string;
  file: string;
  link: string;
  desktop: string;
};

const headers = () => ({
  "Content-Type": "application/json",
  "x-admin-password": localStorage.getItem("admin_password") || "",
});

function maskLink(value: string, visible: boolean) {
  return visible ? value : value.replace(/:([^:@]+)@/, ":***@");
}

function maskPassword(value: string, visible: boolean) {
  return visible ? value : "••••••••";
}

function UserRow({
  user,
  onCopy,
  onDelete,
}: {
  user: User;
  onCopy: (t: string) => void;
  onDelete: (id: string) => void;
}) {
  const [show, setShow] = useState(false);

  return (
    <div className="row">
      <div className="cell">
        <div className="label">USER</div>
        <div className="value">{user.login}</div>
      </div>

      <div className="cell">
        <div className="label">PASSWORD</div>
        <div className="value mono">{maskPassword(user.password, show)}</div>
      </div>

      <div className="cell links">
        <div className="linkItem">
          <div className="labelSmall">Naive</div>
          <div className="mono linkText">{maskLink(user.link, show)}</div>
          <button onClick={() => onCopy(user.link)}>copy</button>
        </div>

        <div className="linkItem">
          <div className="labelSmall">Desktop</div>
          <div className="mono linkText">{maskLink(user.desktop, show)}</div>
          <button onClick={() => onCopy(user.desktop)}>copy</button>
        </div>
      </div>

      <div className="actions">
        <button onClick={() => setShow((v) => !v)}>
          {show ? "hide" : "show"}
        </button>

        <button className="danger" onClick={() => onDelete(user.id)}>
          delete
        </button>
      </div>
    </div>
  );
}

export default function App() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);

  const [prefix, setPrefix] = useState("app");
  const [creating, setCreating] = useState(false);

  const [password, setPassword] = useState(
    () => localStorage.getItem("admin_password") || "",
  );

  const [auth, setAuth] = useState(() => !!password);

  const loadUsers = async () => {
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
      setUsers(data.users ?? []);
    } finally {
      setLoading(false);
    }
  };

  const createUser = async () => {
    setCreating(true);

    try {
      await fetch(`${API}/create-user?prefix=${prefix}`, {
        method: "POST",
        headers: headers(),
      });

      await loadUsers();
    } finally {
      setCreating(false);
    }
  };

  const deleteUser = async (id: string) => {
    if (!confirm(`Delete ${id}?`)) return;

    await fetch(`${API}/users/${id}`, {
      method: "DELETE",
      headers: headers(),
    });

    await loadUsers();
  };

  const copy = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const login = () => {
    localStorage.setItem("admin_password", password);
    setAuth(true);
  };

  useEffect(() => {
    if (!auth) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    loadUsers();
  }, [auth]);

  if (!auth) {
    return (
      <div className="center">
        <div className="card">
          <h2>Login</h2>

          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <button onClick={login}>login</button>
        </div>
      </div>
    );
  }

  return (
    <div className="wrap">
      <header className="header">
        <div className="logo">NAIVE PANEL</div>
        <div className="sub">proxy control system</div>
      </header>

      <div className="toolbar">
        <input
          value={prefix}
          onChange={(e) => setPrefix(e.target.value)}
          placeholder="prefix"
        />

        <button onClick={createUser} disabled={creating}>
          {creating ? "creating..." : "create"}
        </button>
      </div>

      <div className="list">
        {loading ? (
          <div className="loading">loading...</div>
        ) : (
          users.map((u) => (
            <UserRow key={u.id} user={u} onCopy={copy} onDelete={deleteUser} />
          ))
        )}
      </div>
    </div>
  );
}
