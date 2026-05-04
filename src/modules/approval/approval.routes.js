import express from 'express';
import { protect } from '../../middleware/auth.js';
import { getPending, approve, reject } from './approval.controller.js';

const router = express.Router();
router.use(protect);
router.get('/pending', getPending);
router.post('/:requestId/approve', approve);
router.post('/:requestId/reject', reject);

export default router;
