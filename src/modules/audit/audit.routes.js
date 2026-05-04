import express from 'express';
import { protect } from '../../middleware/auth.js';
import { getLogs } from './audit.controller.js';

const router = express.Router();
router.use(protect);
router.get('/', getLogs);

export default router;
