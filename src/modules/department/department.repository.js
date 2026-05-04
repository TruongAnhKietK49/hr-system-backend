import { getPool } from '../../config/database.js';
import { addInput, SqlTypes } from '../../utils/procedure.js';

class DepartmentRepository {
  async findAll() {
    const pool = await getPool();
    const result = await pool.request().execute('sp_Department_List');
    return result.recordset;
  }

  async create(payload) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'DepartmentID', SqlTypes.VarChar, payload.departmentId);
    addInput(request, 'DepartmentName', SqlTypes.NVarChar, payload.departmentName);
    addInput(request, 'ManagerID', SqlTypes.VarChar, payload.managerId);
    const result = await request.execute('sp_Department_Create');
    return result.recordset[0] || null;
  }

  async updateById(id, payload) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'DepartmentID', SqlTypes.VarChar, id);
    addInput(request, 'DepartmentName', SqlTypes.NVarChar, payload.departmentName);
    addInput(request, 'ManagerID', SqlTypes.VarChar, payload.managerId);
    const result = await request.execute('sp_Department_Update');
    return result.recordset[0] || null;
  }

  async deleteById(id) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'DepartmentID', SqlTypes.VarChar, id);
    await request.execute('sp_Department_Delete');
  }
}

export const departmentRepository = new DepartmentRepository();
