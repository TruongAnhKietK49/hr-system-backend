import { getPool } from '../../config/database.js';
import { addInput, SqlTypes } from '../../utils/procedure.js';

class RequestRepository {
  async create({ requestType, requesterId, payload }) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequestType', SqlTypes.VarChar, requestType);
    addInput(request, 'RequesterID', SqlTypes.VarChar, requesterId);
    addInput(request, 'RequestPayload', SqlTypes.MaxNVarChar, JSON.stringify(payload));
    const result = await request.execute('sp_HRRequest_Create');
    return result.recordset[0] || null;
  }

  async findAllByScope(requesterId) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterID', SqlTypes.VarChar, requesterId);
    const result = await request.execute('sp_HRRequest_ListByScope');
    return result.recordset;
  }

  async findByIdByScope(requesterId, requestId) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'RequesterID', SqlTypes.VarChar, requesterId);
    addInput(request, 'RequestID', SqlTypes.Int, requestId);
    const result = await request.execute('sp_HRRequest_GetByIdByScope');
    return result.recordset[0] || null;
  }
}

export const requestRepository = new RequestRepository();
