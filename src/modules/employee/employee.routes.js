import express from 'express';
import { protect } from '../../middleware/auth.js';
import { getAll, getById, update } from './employee.controller.js';

const router = express.Router();
router.use(protect);
router.get('/', getAll);
router.get('/:id', getById);
router.put('/:id', update);

export default router;
