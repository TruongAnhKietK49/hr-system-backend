import assert from 'node:assert/strict';
import http from 'node:http';
import fs from 'node:fs/promises';

import sql from 'mssql';

import app from '../src/app.js';
import { connectDB } from '../src/config/database.js';
import { env } from '../src/config/environment.js';

const PASSWORD = '123456';
const USERS = {
  director01: { role: 'Director', employeeId: 'EM00001' },
  hrmanager01: { role: 'HR Manager', employeeId: 'EM00002' },
  hrstaff01: { role: 'HR Staff', employeeId: 'EM00003' },
  finance01: { role: 'Finance Staff', employeeId: 'EM00004' },
  manager01: { role: 'Manager', employeeId: 'EM00005' },
  employee01: { role: 'Employee', employeeId: 'EM00006' }
};

let server;
let baseUrl;
let pool;
const tests = [];
const sessionCache = new Map();

const registerTest = (name, fn) => {
  tests.push({ name, fn });
};

const getByEmployeeId = (records, employeeId) => records.find((record) => record.EmployeeID === employeeId);

const requestJson = async (path, options = {}) => {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...(options.headers || {})
    }
  });

  const body = await response.json();
  return { status: response.status, body };
};

const login = async (username) => {
  if (sessionCache.has(username)) {
    return sessionCache.get(username);
  }

  const response = await requestJson('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password: PASSWORD })
  });

  assert.equal(response.status, 200, `Login failed for ${username}`);
  sessionCache.set(username, response.body.data);
  return response.body.data;
};

const authorizedRequest = async (username, path, options = {}) => {
  const session = await login(username);
  return requestJson(path, {
    ...options,
    headers: {
      authorization: `Bearer ${session.accessToken}`,
      ...(options.headers || {})
    }
  });
};

const resetDatabase = async () => {
  const files = ['sql/init.sql', 'sql/seed.sql', 'sql/rbac_employee_procs.sql'];

  for (const file of files) {
    const content = await fs.readFile(file, 'utf8');
    const batches = content
      .split(/^\s*GO\s*$/gim)
      .map((batch) => batch.trim())
      .filter(Boolean);

    for (const batch of batches) {
      await pool.request().batch(batch);
    }
  }
};

const startServer = async () => {
  pool = await sql.connect(env.db);
  await resetDatabase();
  await connectDB();

  server = http.createServer(app);
  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();
  baseUrl = `http://127.0.0.1:${address.port}`;
};

const stopServer = async () => {
  if (server) {
    await new Promise((resolve, reject) => {
      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }

  if (pool) {
    await pool.close();
  }
};

registerTest('login works for all seeded users', async () => {
  for (const [username, expected] of Object.entries(USERS)) {
    const session = await login(username);
    assert.equal(session.user.role, expected.role);
    assert.equal(session.user.employeeId, expected.employeeId);
    assert.ok(session.accessToken);
    assert.ok(session.refreshToken);
  }
});

registerTest('employee list follows SQL RBAC for all seeded roles', async () => {
  const directorResponse = await authorizedRequest('director01', '/api/employees');
  assert.equal(directorResponse.status, 200);
  assert.equal(directorResponse.body.data.length, 6);
  assert.ok('BaseSalary' in getByEmployeeId(directorResponse.body.data, 'EM00006'));

  const hrManagerResponse = await authorizedRequest('hrmanager01', '/api/employees');
  assert.equal(hrManagerResponse.status, 200);
  assert.equal(hrManagerResponse.body.data.length, 6);
  assert.equal('BaseSalary' in getByEmployeeId(hrManagerResponse.body.data, 'EM00006'), false);

  const hrStaffResponse = await authorizedRequest('hrstaff01', '/api/employees');
  assert.equal(hrStaffResponse.status, 200);
  assert.equal(hrStaffResponse.body.data.some((row) => row.DepartmentID === 'D001'), false);

  const financeResponse = await authorizedRequest('finance01', '/api/employees');
  assert.equal(financeResponse.status, 200);
  const financeMasked = getByEmployeeId(financeResponse.body.data, 'EM00005');
  assert.equal(financeMasked.FullName, null);
  assert.ok('Allowance' in financeMasked);
  assert.equal('BaseSalary' in financeMasked, false);

  const managerResponse = await authorizedRequest('manager01', '/api/employees');
  assert.equal(managerResponse.status, 200);
  assert.equal(managerResponse.body.data.length, 2);
  assert.equal(managerResponse.body.data.every((row) => row.DepartmentID === 'D003'), true);

  const employeeResponse = await authorizedRequest('employee01', '/api/employees');
  assert.equal(employeeResponse.status, 200);
  assert.equal(employeeResponse.body.data.length, 2);
  assert.equal('FinalSalary' in getByEmployeeId(employeeResponse.body.data, 'EM00006'), false);
});

registerTest('employee detail follows SQL RBAC for Director, Finance, Manager, Employee', async () => {
  const directorResponse = await authorizedRequest('director01', '/api/employees/EM00006');
  assert.equal(directorResponse.status, 200);
  assert.ok('BaseSalary' in directorResponse.body.data);

  const financeResponse = await authorizedRequest('finance01', '/api/employees/EM00005');
  assert.equal(financeResponse.status, 200);
  assert.equal(financeResponse.body.data.FullName, null);
  assert.ok('FinalSalary' in financeResponse.body.data);

  const managerResponse = await authorizedRequest('manager01', '/api/employees/EM00006');
  assert.equal(managerResponse.status, 200);
  assert.equal(managerResponse.body.data.EmployeeID, 'EM00006');

  const employeeInScope = await authorizedRequest('employee01', '/api/employees/EM00005');
  assert.equal(employeeInScope.status, 200);
  assert.equal(employeeInScope.body.data.EmployeeID, 'EM00005');

  const employeeOutOfScope = await authorizedRequest('employee01', '/api/employees/EM00004');
  assert.equal(employeeOutOfScope.status, 404);
});

registerTest('salary list and salary detail endpoints enforce role-specific field visibility', async () => {
  const directorList = await authorizedRequest('director01', '/api/salaries');
  assert.equal(directorList.status, 200);
  assert.equal(directorList.body.data.length, 6);
  assert.ok('BaseSalary' in getByEmployeeId(directorList.body.data, 'EM00006'));

  const financeList = await authorizedRequest('finance01', '/api/salaries');
  assert.equal(financeList.status, 200);
  assert.equal(financeList.body.data.length, 6);
  const financeMasked = getByEmployeeId(financeList.body.data, 'EM00005');
  assert.equal(financeMasked.FullName, null);
  assert.equal(financeMasked.BaseSalary, null);

  const financeDetail = await authorizedRequest('finance01', '/api/salaries/EM00005');
  assert.equal(financeDetail.status, 200);
  assert.equal(financeDetail.body.data.FullName, null);
  assert.equal(financeDetail.body.data.BaseSalary, null);

  const directorDetail = await authorizedRequest('director01', '/api/salaries/EM00006');
  assert.equal(directorDetail.status, 200);
  assert.equal(directorDetail.body.data.FinalSalary, '11500000');
  assert.ok('BaseSalary' in directorDetail.body.data);
});

registerTest('finance payroll endpoints are backward-compatible aliases for salary reads', async () => {
  const listResponse = await authorizedRequest('finance01', '/api/finance/payroll');
  assert.equal(listResponse.status, 200);
  assert.equal(listResponse.body.data.length, 6);
  assert.equal(getByEmployeeId(listResponse.body.data, 'EM00005').BaseSalary, null);

  const detailResponse = await authorizedRequest('director01', '/api/finance/payroll/EM00006');
  assert.equal(detailResponse.status, 200);
  assert.ok('BaseSalary' in detailResponse.body.data);
});

registerTest('director can update salary through dedicated salary module and restore the seed value', async () => {
  const updateResponse = await authorizedRequest('director01', '/api/salaries/EM00006', {
    method: 'PUT',
    body: JSON.stringify({
      baseSalary: 15000000,
      salaryCoefficient: 1.25,
      positionCoefficient: 1.1,
      allowance: 700000,
      formulaVersion: 'v2'
    })
  });

  assert.equal(updateResponse.status, 200);
  assert.equal(updateResponse.body.data.FinalSalary, '21325000.00');
  assert.equal(updateResponse.body.data.FormulaVersion, 'v2');

  const restoreResponse = await authorizedRequest('director01', '/api/salaries/EM00006', {
    method: 'PUT',
    body: JSON.stringify({
      baseSalary: 10000000,
      salaryCoefficient: 1.1,
      positionCoefficient: 1.0,
      allowance: 500000,
      formulaVersion: 'v1'
    })
  });

  assert.equal(restoreResponse.status, 200);
  assert.equal(restoreResponse.body.data.FinalSalary, '11500000.00');
  assert.equal(restoreResponse.body.data.FormulaVersion, 'v1');
});

registerTest('wrong role paths are blocked', async () => {
  const salaryForEmployee = await authorizedRequest('employee01', '/api/salaries');
  assert.equal(salaryForEmployee.status, 403);

  const salaryUpdateForFinance = await authorizedRequest('finance01', '/api/salaries/EM00006', {
    method: 'PUT',
    body: JSON.stringify({
      baseSalary: 10000000,
      salaryCoefficient: 1.1,
      positionCoefficient: 1,
      allowance: 500000,
      formulaVersion: 'v1'
    })
  });
  assert.equal(salaryUpdateForFinance.status, 403);

  const approvalsForManager = await authorizedRequest('manager01', '/api/approvals/pending');
  assert.equal(approvalsForManager.status, 403);

  const auditForFinance = await authorizedRequest('finance01', '/api/audit-logs');
  assert.equal(auditForFinance.status, 403);
});

registerTest('validation rejects invalid salary payloads and employee sensitive field updates', async () => {
  const invalidSalary = await authorizedRequest('director01', '/api/salaries/EM00006', {
    method: 'PUT',
    body: JSON.stringify({
      baseSalary: -1,
      salaryCoefficient: 1.1,
      positionCoefficient: 1,
      allowance: 500000,
      formulaVersion: 'v1'
    })
  });
  assert.equal(invalidSalary.status, 400);

  const invalidEmployeeUpdate = await authorizedRequest('employee01', '/api/employees/EM00006', {
    method: 'PUT',
    body: JSON.stringify({ departmentId: 'D001' })
  });
  assert.equal(invalidEmployeeUpdate.status, 400);
  assert.equal(invalidEmployeeUpdate.body.message, 'No allowed fields to update');
});

registerTest('HR request endpoints return password-masked payloads from SQL', async () => {
  const requestList = await authorizedRequest('hrstaff01', '/api/hr-requests');
  assert.equal(requestList.status, 200);
  assert.equal(requestList.body.data.length, 3);
  assert.equal('password' in JSON.parse(requestList.body.data[0].RequestPayload), false);

  const requestDetail = await authorizedRequest('director01', '/api/hr-requests/1');
  assert.equal(requestDetail.status, 200);
  assert.equal('password' in JSON.parse(requestDetail.body.data.RequestPayload), false);
});

registerTest('Swagger/OpenAPI endpoints are exposed', async () => {
  const jsonResponse = await requestJson('/api-docs/openapi.json');
  assert.equal(jsonResponse.status, 200);
  assert.equal(jsonResponse.body.openapi, '3.0.3');
  assert.ok(jsonResponse.body.paths['/api/salaries']);

  const htmlResponse = await fetch(`${baseUrl}/api-docs`);
  assert.equal(htmlResponse.status, 200);
  const html = await htmlResponse.text();
  assert.ok(html.includes('swagger-ui'));
});

registerTest('director pending approvals endpoint still works after SQL sync', async () => {
  const response = await authorizedRequest('director01', '/api/approvals/pending');
  assert.equal(response.status, 200);
  assert.equal(response.body.data.some((row) => row.Status === 'PENDING'), true);
});

registerTest('department creation uses backend-generated DepartmentID and ignores legacy input', async () => {
  const createWithoutId = await authorizedRequest('hrmanager01', '/api/departments', {
    method: 'POST',
    body: JSON.stringify({
      departmentName: 'Product'
    })
  });

  assert.equal(createWithoutId.status, 201);
  assert.equal(createWithoutId.body.data.DepartmentID, 'D005');

  await pool.request().batch(`
    INSERT INTO Department (DepartmentID, DepartmentName)
    VALUES ('D010', N'Legacy Gap Department');

    INSERT INTO Department (DepartmentID, DepartmentName)
    VALUES ('ABC', N'Invalid Code Department');

    INSERT INTO Department (DepartmentID, DepartmentName)
    VALUES ('DEP02', N'Legacy Text Code Department');
  `);

  const createWithLegacyId = await authorizedRequest('director01', '/api/departments', {
    method: 'POST',
    body: JSON.stringify({
      departmentId: 'D999',
      departmentName: 'Platform'
    })
  });

  assert.equal(createWithLegacyId.status, 201);
  assert.equal(createWithLegacyId.body.data.DepartmentID, 'D011');

  const createNext = await authorizedRequest('director01', '/api/departments', {
    method: 'POST',
    body: JSON.stringify({
      departmentName: 'Customer Success'
    })
  });

  assert.equal(createNext.status, 201);
  assert.equal(createNext.body.data.DepartmentID, 'D012');

  const departments = await authorizedRequest('director01', '/api/departments');
  assert.equal(departments.status, 200);
  assert.equal(
    departments.body.data.filter((department) =>
      ['D005', 'D011', 'D012'].includes(department.DepartmentID)
    ).length,
    3
  );
});

registerTest('CREATE_EMPLOYEE request does not require EmployeeID and approval generates official EmployeeID', async () => {
  const createRequest = await authorizedRequest('hrstaff01', '/api/hr-requests', {
    method: 'POST',
    body: JSON.stringify({
      requestType: 'CREATE_EMPLOYEE',
      payload: {
        fullName: 'Generated Employee User',
        gender: 'Female',
        dateOfBirth: '2001-02-03',
        phoneNumber: '0901777777',
        taxId: '777777001',
        departmentId: 'D003',
        positionId: 1,
        username: 'generatedemp01',
        password: '123456',
        role: 'Employee'
      }
    })
  });

  assert.equal(createRequest.status, 201);
  assert.ok(createRequest.body.data.RequestID);

  const approveResponse = await authorizedRequest(
    'director01',
    `/api/approvals/${createRequest.body.data.RequestID}/approve`,
    {
      method: 'POST',
      body: JSON.stringify({
        baseSalary: 12000000,
        salaryCoefficient: 1.2,
        positionCoefficient: 1,
        allowance: 1000000,
        formulaVersion: 'v1'
      })
    }
  );

  assert.equal(approveResponse.status, 200);
  assert.equal(approveResponse.body.data.EmployeeID, 'EM00007');

  const employee = await authorizedRequest('director01', '/api/employees/EM00007');
  assert.equal(employee.status, 200);
  assert.equal(employee.body.data.FullName, 'Generated Employee User');

  const salary = await authorizedRequest('director01', '/api/salaries/EM00007');
  assert.equal(salary.status, 200);
  assert.equal(salary.body.data.FinalSalary, '15400000.00');

  const account = await pool
    .request()
    .input('Username', sql.VarChar, 'generatedemp01')
    .query('SELECT EmployeeID, Username, Role FROM Account WHERE Username = @Username');

  assert.equal(account.recordset[0].EmployeeID, 'EM00007');
  assert.equal(account.recordset[0].Role, 'Employee');

  const hrRequest = await pool
    .request()
    .input('RequestID', sql.Int, createRequest.body.data.RequestID)
    .query('SELECT Status, ApproverID FROM HR_Request WHERE RequestID = @RequestID');

  assert.equal(hrRequest.recordset[0].Status, 'APPROVED');
  assert.equal(hrRequest.recordset[0].ApproverID, 'EM00001');

  const audit = await pool
    .request()
    .input('RequestID', sql.VarChar, String(createRequest.body.data.RequestID))
    .query(`
      SELECT ActionType, TableName, RecordID, NewValues
      FROM Audit_Log
      WHERE ActionType = 'APPROVE_HR_REQUEST'
        AND TableName = 'HR_Request'
        AND RecordID = @RequestID
    `);

  assert.equal(audit.recordset.length, 1);
  assert.match(audit.recordset[0].NewValues, /EM00007/);

  const employeeAudit = await pool
    .request()
    .input('EmployeeID', sql.VarChar, 'EM00007')
    .query(`
      SELECT ActionType, TableName, RecordID, NewValues
      FROM Audit_Log
      WHERE ActionType = 'CREATE_EMPLOYEE'
        AND TableName = 'Employee'
        AND RecordID = @EmployeeID
    `);

  assert.equal(employeeAudit.recordset.length, 1);
  assert.match(employeeAudit.recordset[0].NewValues, /Generated Employee User/);
});

const run = async () => {
  let failed = false;

  try {
    await startServer();

    for (const { name, fn } of tests) {
      try {
        await fn();
        console.log(`PASS ${name}`);
      } catch (error) {
        failed = true;
        console.error(`FAIL ${name}`);
        console.error(error);
      }
    }
  } finally {
    await stopServer();
  }

  if (failed) {
    process.exitCode = 1;
    return;
  }

  console.log(`PASS ${tests.length}/${tests.length} integration checks`);
};

await run();
