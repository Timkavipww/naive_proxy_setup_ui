export type Lang = "ru" | "eu";

export type ToastType = "success" | "error" | "info";

export type PushFn = (msg: string, type: ToastType) => void;

export type Translation = {
  userCreated: string;
  cannotDelete: string;
  delete: string;
};

export const dict = {
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
