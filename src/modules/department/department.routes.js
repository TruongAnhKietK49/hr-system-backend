import express from 'express';
import { protect } from '../../middleware/auth.js';
import { getAll, create, update, remove } from './department.controller.js';

const router = express.Router();
router.use(protect);
router.get('/', getAll);
router.post('/', create);
router.put('/:id', update);
router.delete('/:id', remove);

export default router;
