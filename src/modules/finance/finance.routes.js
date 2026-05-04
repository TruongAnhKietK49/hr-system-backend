import express from 'express';
import { protect } from '../../middleware/auth.js';
import { getPayroll, getPayrollById } from './finance.controller.js';

const router = express.Router();
router.use(protect);
router.get('/payroll', getPayroll);
router.get('/payroll/:id', getPayrollById);

export default router;
