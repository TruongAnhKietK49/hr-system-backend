import express from "express";

import { protect } from "../../middleware/auth.js";
import {
  create,
  getAll,
  remove,
  searchManagerCandidates,
  update,
} from "./department.controller.js";

const router = express.Router();

router.use(protect);

router.get("/", getAll);
router.get("/manager-candidates", searchManagerCandidates);
router.post("/", create);
router.put("/:id", update);
router.delete("/:id", remove);

export default router;
