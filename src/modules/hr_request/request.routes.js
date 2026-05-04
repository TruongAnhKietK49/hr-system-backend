import express from 'express';
import { protect } from '../../middleware/auth.js';
import { create, getAll, getById } from './request.controller.js';

const router = express.Router();
router.use(protect);
router.post('/', create);
router.get('/', getAll);
router.get('/:id', getById);

export default router;
