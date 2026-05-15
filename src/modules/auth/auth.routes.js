import express from "express";
import { login, refresh, changePassword } from "./auth.controller.js";
import { protect } from "../../middleware/auth.js";

const router = express.Router();

router.post("/login", login);
router.post("/refresh", refresh);
router.post("/change-password", protect, changePassword);

export default router;
