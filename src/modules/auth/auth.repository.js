import { getPool } from '../../config/database.js';
import { addInput, SqlTypes } from '../../utils/procedure.js';

class AuthRepository {
  async findAccountByUsername(username) {
    const pool = await getPool();
    const request = pool.request();
    addInput(request, 'Username', SqlTypes.VarChar, username);
    const result = await request.execute('sp_Auth_GetAccountByUsername');
    return result.recordset[0] || null;
  }
}

export const authRepository = new AuthRepository();
