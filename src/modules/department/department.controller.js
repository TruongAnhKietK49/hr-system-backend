import { departmentService } from './department.service.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { success } from '../../utils/apiResponse.js';
import { validate, departmentCreateSchema, departmentUpdateSchema } from '../../validations/schemas.js';

export const getAll = asyncHandler(async (req, res) => {
  const data = await departmentService.getAll();
  return success(res, data, 'Departments fetched');
});

export const create = asyncHandler(async (req, res) => {
  const payload = validate(departmentCreateSchema, req.body);
  const data = await departmentService.create(req.user, payload);
  return success(res, data, 'Department created', 201);
});

export const update = asyncHandler(async (req, res) => {
  const payload = validate(departmentUpdateSchema, req.body);
  const data = await departmentService.update(req.user, req.params.id, payload);
  return success(res, data, 'Department updated');
});

export const remove = asyncHandler(async (req, res) => {
  await departmentService.delete(req.user, req.params.id);
  return success(res, null, 'Department deleted');
});
