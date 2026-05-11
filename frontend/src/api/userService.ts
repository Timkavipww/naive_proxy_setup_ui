import { api } from "./axios";
import type { User } from "../types/user";

export const userService = {
  async getUsers(): Promise<User[]> {
    const res = await api.get("/users");
    return res.data.users;
  },

  async createUser(prefix: string) {
    await api.post(`/create-user?prefix=${prefix}`);
  },

  async deleteUser(id: string) {
    await api.delete(`/users/${id}`);
  },
};
