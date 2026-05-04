import { financeService } from './finance.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';

export const getPayroll = asyncHandler(async (req, res) => {
  const data = await financeService.getPayroll(req.user);
  return success(res, data, 'Payroll fetched');
});

export const getPayrollById = asyncHandler(async (req, res) => {
  const data = await financeService.getPayrollById(req.user, req.params.id);
  return success(res, data, 'Payroll detail fetched');
});
