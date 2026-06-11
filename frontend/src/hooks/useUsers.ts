import { useCallback, useState } from "react";
import { userService } from "../api/userService";
import type { User } from "../types/user";
import type { PushFn, Translation } from "../types/constants.types";

export function useUsers(push: PushFn, t: Translation) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await userService.getUsers();
      setUsers(data);
    } finally {
      setLoading(false);
    }
  }, []);

  const createUser = async (prefix: string) => {
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

  return {
    users,
    loading,
    creating,
    loadUsers,
    createUser,
    deleteUser,
    setUsers,
  };
}
