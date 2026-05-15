import { getPool } from "../../config/database.js";
import { addInput, SqlTypes } from "../../utils/procedure.js";

class AuthRepository {
  async findAccountByUsername(username) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "Username", SqlTypes.VarChar, username);

    const result = await request.execute("sp_Auth_GetAccountByUsername");
    return result.recordset[0] || null;
  }

  async updatePasswordByEmployeeId({ employeeId, passwordHash, passwordSalt }) {
    const pool = await getPool();
    const request = pool.request();

    addInput(request, "EmployeeID", SqlTypes.VarChar, employeeId);
    addInput(request, "PasswordHash", SqlTypes.NVarChar, passwordHash);
    addInput(request, "PasswordSalt", SqlTypes.NVarChar, passwordSalt);

    await request.query(`
      UPDATE Account
      SET
        PasswordHash = @PasswordHash,
        PasswordSalt = @PasswordSalt
      WHERE EmployeeID = @EmployeeID
        AND IsActive = 1
        AND AccountStatus = 'ACTIVE';
    `);
  }
}

export const authRepository = new AuthRepository();
