# HR Management Security System Backend API Documentation

## 0. Inventory trước khi document

### 0.1. Tất cả endpoint tìm thấy

| # | Method | Path | Module / nguồn |
| --- | --- | --- | --- |
| 1 | GET | `/health` | `src/app.js` |
| 2 | POST | `/api/auth/login` | `src/modules/auth/auth.routes.js` |
| 3 | POST | `/api/auth/refresh` | `src/modules/auth/auth.routes.js` |
| 4 | GET | `/api/departments` | `src/modules/department/department.routes.js` |
| 5 | POST | `/api/departments` | `src/modules/department/department.routes.js` |
| 6 | PUT | `/api/departments/:id` | `src/modules/department/department.routes.js` |
| 7 | DELETE | `/api/departments/:id` | `src/modules/department/department.routes.js` |
| 8 | POST | `/api/hr-requests` | `src/modules/hr_request/request.routes.js` |
| 9 | GET | `/api/hr-requests` | `src/modules/hr_request/request.routes.js` |
| 10 | GET | `/api/hr-requests/:id` | `src/modules/hr_request/request.routes.js` |
| 11 | GET | `/api/approvals/pending` | `src/modules/approval/approval.routes.js` |
| 12 | POST | `/api/approvals/:requestId/approve` | `src/modules/approval/approval.routes.js` |
| 13 | POST | `/api/approvals/:requestId/reject` | `src/modules/approval/approval.routes.js` |
| 14 | GET | `/api/employees` | `src/modules/employee/employee.routes.js` |
| 15 | GET | `/api/employees/:id` | `src/modules/employee/employee.routes.js` |
| 16 | PUT | `/api/employees/:id` | `src/modules/employee/employee.routes.js` |
| 17 | GET | `/api/salaries` | `src/modules/salary/salary.routes.js` |
| 18 | GET | `/api/salaries/:id` | `src/modules/salary/salary.routes.js` |
| 19 | PUT | `/api/salaries/:id` | `src/modules/salary/salary.routes.js` |
| 20 | GET | `/api/finance/payroll` | `src/modules/finance/finance.routes.js` |
| 21 | GET | `/api/finance/payroll/:id` | `src/modules/finance/finance.routes.js` |
| 22 | GET | `/api/audit-logs` | `src/modules/audit/audit.routes.js` |
| 23 | GET | `/api-docs/openapi.json` | `src/modules/docs/docs.routes.js` |
| 24 | GET | `/api-docs` | `src/modules/docs/docs.routes.js` |

### 0.2. Tất cả file SQL và object DB quan trọng tìm thấy

#### SQL files

| File | Mục đích |
| --- | --- |
| `sql/init.sql` | Khởi tạo database, table, encryption artifacts, helper function, auth/department/request/approval/audit procedures |
| `sql/seed.sql` | Seed department, position, employee, account, salary data, sample HR requests, sample audit logs |
| `sql/rbac_employee_procs.sql` | Tạo DB roles, `DENY/GRANT`, employee procedures theo role, salary procedures theo role |

#### Tables

- `Department`
- `Position`
- `Employee`
- `EmployeeSalaryConfig`
- `EmployeeSalaryResult`
- `Account`
- `HR_Request`
- `Audit_Log`

#### Security / encryption objects

- `MASTER KEY` for database
- Certificate: `HRSystemCertificate`
- Symmetric key: `HRSystemSymmetricKey`

#### Functions

- `fn_RequesterContext`

#### Stored procedures

- `sp_AuditLog_Create`
- `sp_AuditLog_List`
- `sp_Auth_GetAccountByUsername`
- `sp_Department_List`
- `sp_Department_Create`
- `sp_Department_Update`
- `sp_Department_Delete`
- `sp_Salary_UpsertCore`
- `sp_HRRequest_Create`
- `sp_HRRequest_ListByScope`
- `sp_HRRequest_GetByIdByScope`
- `sp_Approval_ListPending_ForDirector`
- `sp_Approval_GetRequestForDirector`
- `sp_Approval_RejectRequest`
- `sp_Approval_ApproveCreateEmployee`
- `sp_Employee_GetList_ForEmployee`
- `sp_Employee_GetById_ForEmployee`
- `sp_Employee_GetList_ForManager`
- `sp_Employee_GetById_ForManager`
- `sp_Employee_GetList_ForHRStaff`
- `sp_Employee_GetById_ForHRStaff`
- `sp_Employee_GetList_ForHRManager`
- `sp_Employee_GetById_ForHRManager`
- `sp_Employee_GetList_ForFinance`
- `sp_Employee_GetById_ForFinance`
- `sp_Employee_GetList_ForDirector`
- `sp_Employee_GetById_ForDirector`
- `sp_Employee_UpdateProfile_ForEmployee`
- `sp_Employee_UpdateProfile_ForHRStaff`
- `sp_Employee_UpdateProfile_ForHRManager`
- `sp_Salary_GetList_ForDirector`
- `sp_Salary_GetByEmployeeId_ForDirector`
- `sp_Salary_GetList_ForFinance`
- `sp_Salary_GetByEmployeeId_ForFinance`
- `sp_Salary_Update_ForDirector`

#### Database roles

- `rl_employee`
- `rl_manager`
- `rl_hrstaff`
- `rl_hrmanager`
- `rl_finance`
- `rl_director`

#### `DENY/GRANT`

Observed in SQL:
- `DENY` direct `SELECT`/`INSERT`/`UPDATE`/`DELETE` trên bảng nhạy cảm cho `PUBLIC`
- `GRANT EXECUTE` theo procedure và DB role

#### Views / triggers / SQL scalar functions khác

- Views: `Not found / needs verification`
- Triggers: `Not found / needs verification`
- User-defined functions khác ngoài `fn_RequesterContext`: `Not found / needs verification`

---

## 1. Tổng quan hệ thống

### 1.1. Tên project

`HR Management Security System`

### 1.2. Mục tiêu hệ thống

Backend cho hệ thống quản lý nhân sự có trọng tâm là bảo vệ dữ liệu nhạy cảm ở tầng database và RBAC theo role nghiệp vụ:

- Employee
- Manager
- HR Staff
- HR Manager
- Finance Staff
- Director

### 1.3. Tech stack

Observed in code:
- Node.js ESM
- Express
- SQL Server
- `mssql`
- `jsonwebtoken`
- `bcryptjs`
- `joi`
- `helmet`
- `cors`
- `morgan`

### 1.4. Kiến trúc backend tổng quát

Observed in code:

`route -> controller -> service -> repository -> stored procedure`

Ý nghĩa:
- Router khai báo endpoint và gắn `protect`.
- Controller validate input và chuẩn hóa response.
- Service xử lý business rule và role check ở tầng app.
- Repository chỉ gọi stored procedure, không query bảng trực tiếp.
- SQL procedures thực thi row-level / field-level restriction cho employee/salary.

### 1.5. Cơ chế auth

Observed in code:
- Access token: JWT ký bằng `JWT_SECRET`
- Refresh token: JWT ký bằng `JWT_REFRESH_SECRET`
- Access token verify ở middleware `protect`
- Login đọc account qua `sp_Auth_GetAccountByUsername`
- Password verify bằng `bcrypt.compare`

### 1.6. Cơ chế RBAC

Observed in code:
- Route level chủ yếu chỉ có `protect`
- Role check ở service cho department, request creation, approval, salary, audit
- Role-specific procedure dispatch ở `employee.rbac.js` và `salary.rbac.js`

Observed in SQL:
- `fn_RequesterContext` lấy role + department từ `Account` và `Employee`
- Mỗi role có procedure list/detail/update riêng cho employee
- Finance và Director có salary procedures riêng
- `DENY` direct table access và `GRANT EXECUTE` theo DB role

Inferred from naming/flow:
- Vì app kết nối DB bằng 1 account dùng chung từ `.env`, enforcement runtime chủ yếu đến từ stored procedure logic dùng `RequesterEmployeeID`, không phải từ SQL principal switching theo từng user ứng dụng.

### 1.7. Ghi chú về database security

Observed in SQL:
- `TaxIDEncrypted`, `BaseSalaryEncrypted`, `SalaryCoefficientEncrypted`, `PositionCoefficientEncrypted`, `AllowanceEncrypted`, `FinalSalaryEncrypted` đều lưu dạng `VARBINARY(MAX)`
- Dùng `EncryptByKey` / `DecryptByKey` với symmetric key AES-256
- `sp_Salary_UpsertCore` là nơi duy nhất tính `FinalSalary`
- `Audit_Log` lưu action trail cho login/request/approval/department/salary/employee update

Quan sát quan trọng theo nghiệp vụ:
- Salary không được nhập tay dưới dạng `FinalSalary`: `Observed in SQL`, vì `FinalSalary` luôn được tính trong `sp_Salary_UpsertCore`
- Công thức: `FinalSalary = (BaseSalary × SalaryCoefficient × PositionCoefficient) + Allowance`
- Director là role nhạy cảm nhất trong approval/salary flow: `Observed in code` + `Observed in SQL`

---

## 2. Tổng quan API

### 2.1. Base URL

- Observed in OpenAPI: `http://localhost:3000`
- Observed in environment: port mặc định `3000`, prefix chính là `/api`
- Ngoại lệ ngoài `/api`: `/health`, `/api-docs`, `/api-docs/openapi.json`

### 2.2. Versioning strategy

- `Not found / needs verification`
- Không thấy `/v1` trong path
- Version hiện có ở package/OpenAPI info là `1.0.0`, nhưng không phải URL versioning

### 2.3. Response format chuẩn toàn hệ thống

Observed in code qua `src/utils/apiResponse.js`:

```json
{
  "success": true,
  "message": "Some message",
  "data": {},
  "meta": null
}
```

Ghi chú:
- Phần lớn API business dùng wrapper trên
- `meta` tồn tại trong helper nhưng chưa thấy endpoint nào truyền pagination meta thật

### 2.4. Error format chuẩn toàn hệ thống

Observed in code qua `errorHandler`:

```json
{
  "success": false,
  "message": "Error message"
}
```

Ghi chú:
- Không có `errorCode`, `details`, `stack`, `traceId`
- SQL errors không được map riêng, nên nhiều lỗi business từ procedure có thể rơi về HTTP `500`

### 2.5. Authentication mechanism

- Public endpoints: `/health`, `/api/auth/*`, `/api-docs*`
- Protected endpoints: tất cả API nghiệp vụ khác
- Access token truyền qua header:

```http
Authorization: Bearer <access_token>
```

### 2.6. Refresh token flow

Observed in code:
1. `POST /api/auth/login` trả `accessToken` + `refreshToken`
2. `POST /api/auth/refresh` nhận body `{ "refreshToken": "..." }`
3. Server verify refresh token và trả access token mới

Not found / needs verification:
- Không có logout endpoint
- Không có refresh token persistence
- Không có revoke / blacklist / rotation

### 2.7. HTTP status code đang dùng

Observed in code/tests:
- `200 OK`
- `201 Created`
- `400 Bad Request`
- `401 Unauthorized`
- `403 Forbidden`
- `404 Not Found`
- `500 Internal Server Error`

### 2.8. Endpoint response không theo wrapper chuẩn

Observed in code:
- `GET /health` trả raw JSON
- `GET /api-docs/openapi.json` trả raw OpenAPI object
- `GET /api-docs` trả HTML

---

## 3. Permission Matrix

Ký hiệu:
- `Y`: được gọi
- `N`: không được gọi
- `Y(self)`: chỉ self
- `Y(scope)`: được gọi nhưng dữ liệu bị giới hạn theo scope
- `Y(masked)`: được gọi nhưng field nhạy cảm bị ẩn/mask
- `Public`: không cần role

| Endpoint | Method | Employee | Manager | HR Staff | HR Manager | Finance Staff | Director | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `/health` | GET | Public | Public | Public | Public | Public | Public | Không auth |
| `/api/auth/login` | POST | Public | Public | Public | Public | Public | Public | Login bằng username/password |
| `/api/auth/refresh` | POST | Public | Public | Public | Public | Public | Public | Refresh bằng refresh token |
| `/api/departments` | GET | Y | Y | Y | Y | Y | Y | Mọi user đã auth đều xem được danh sách phòng ban |
| `/api/departments` | POST | N | N | N | Y | N | Y | Check role ở service; proc không check actor role |
| `/api/departments/:id` | PUT | N | N | N | Y | N | Y | Check role ở service |
| `/api/departments/:id` | DELETE | N | N | N | Y | N | Y | Check role ở service |
| `/api/hr-requests` | POST | N | N | Y | N | N | N | Chỉ HR Staff tạo request `CREATE_EMPLOYEE` |
| `/api/hr-requests` | GET | N | N | Y(scope) | Y | N | Y | HR Staff chỉ thấy request của mình; payload được mask password |
| `/api/hr-requests/:id` | GET | N | N | Y(scope) | Y | N | Y | HR Staff chỉ xem request của mình; payload được mask password |
| `/api/approvals/pending` | GET | N | N | N | N | N | Y | Chỉ Director |
| `/api/approvals/:requestId/approve` | POST | N | N | N | N | N | Y | Director nhập salary formula inputs, hệ thống tính final salary |
| `/api/approvals/:requestId/reject` | POST | N | N | N | N | N | Y | Chỉ Director |
| `/api/employees` | GET | Y(scope) | Y(scope) | Y(scope) | Y | Y(masked) | Y | Row-level và field-level restriction ở SQL |
| `/api/employees/:id` | GET | Y(scope) | Y(scope) | Y(scope) | Y | Y(masked) | Y | Employee thấy cùng department; Finance thấy profile masked ngoài phòng Finance |
| `/api/employees/:id` | PUT | Y(self) | N | Y(scope) | Y | N | N | Salary fields không update tại endpoint này |
| `/api/salaries` | GET | N | N | N | N | Y(masked) | Y | Finance chỉ thấy final salary-safe fields; Director thấy full formula inputs |
| `/api/salaries/:id` | GET | N | N | N | N | Y(masked) | Y | Tương tự list |
| `/api/salaries/:id` | PUT | N | N | N | N | N | Y | Chỉ Director |
| `/api/finance/payroll` | GET | N | N | N | N | Y(masked) | Y | Alias của salary list |
| `/api/finance/payroll/:id` | GET | N | N | N | N | Y(masked) | Y | Alias của salary detail |
| `/api/audit-logs` | GET | N | N | N | Y | N | Y | Có filter query, nhưng không có total/meta |
| `/api-docs/openapi.json` | GET | Public | Public | Public | Public | Public | Public | Public OpenAPI spec |
| `/api-docs` | GET | Public | Public | Public | Public | Public | Public | Public Swagger UI HTML |

Field-level restriction quan trọng:
- HR Staff không thấy `BaseSalary`, `SalaryCoefficient`, `PositionCoefficient`, `FinalSalary` ở employee/salary endpoints: `Observed in code` + `Observed in SQL`
- HR Manager không có salary formula inputs trong employee/salary read: `Observed in code` + `Observed in SQL`
- Finance Staff chỉ có allowance/final salary trên salary endpoints; profile ngoài Finance bị mask: `Observed in SQL`
- Director thấy đầy đủ salary config/result ở employee và salary endpoints: `Observed in SQL`
- Manager hiện đang thấy `Allowance` và `FinalSalary` trong employee endpoints: `Observed in SQL`, nhưng đây là điểm lệch so với security expectation chung, xem section 8

---

## 4. Module-by-module API documentation

### 4.1. Infrastructure

#### 4.1.1. Health Check

1. Endpoint name: Health Check
2. Method: `GET`
3. Full path: `/health`
4. Mục đích nghiệp vụ: Kiểm tra server đang chạy
5. Role được phép gọi: Public
6. Middleware / auth / validation áp dụng: `helmet`, `cors`, `express.json`, `logger`; không `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers: Không bắt buộc
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /health
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Server is running"
}
```

14. Example success response:

```json
{
  "success": true,
  "message": "Server is running"
}
```

15. Error cases: Không thấy custom error case
16. Example error responses: `Not found / needs verification`
17. Business rules: Chỉ để health monitoring
18. Database interaction liên quan: Không có
19. Stored procedure / table / view / trigger liên quan: Không có
20. Audit / logging behavior nếu có: `morgan` request log
21. Security notes: Không auth; endpoint không theo wrapper chuẩn của `apiResponse`
22. Field visibility notes theo role: Không áp dụng

#### 4.1.2. OpenAPI JSON

1. Endpoint name: OpenAPI Spec JSON
2. Method: `GET`
3. Full path: `/api-docs/openapi.json`
4. Mục đích nghiệp vụ: Expose OpenAPI spec cho Swagger UI/tooling
5. Role được phép gọi: Public
6. Middleware / auth / validation áp dụng: `logger`; không `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers: Không bắt buộc
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api-docs/openapi.json
```

13. Success response schema: raw OpenAPI 3.0.3 object
14. Example success response:

```json
{
  "openapi": "3.0.3",
  "info": {
    "title": "HR Management Security System API",
    "version": "1.0.0"
  }
}
```

15. Error cases: Không thấy custom error case
16. Example error responses: `Not found / needs verification`
17. Business rules: Dùng cho docs
18. Database interaction liên quan: Không có
19. Stored procedure / table / view / trigger liên quan: Không có
20. Audit / logging behavior nếu có: `morgan` request log
21. Security notes: Public endpoint, lộ inventory API
22. Field visibility notes theo role: Không áp dụng

#### 4.1.3. Swagger UI HTML

1. Endpoint name: Swagger UI
2. Method: `GET`
3. Full path: `/api-docs`
4. Mục đích nghiệp vụ: Render Swagger UI
5. Role được phép gọi: Public
6. Middleware / auth / validation áp dụng: `logger`; không `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers: Không bắt buộc
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api-docs
```

13. Success response schema: HTML document
14. Example success response: HTML có `<div id="swagger-ui"></div>`
15. Error cases: Không thấy custom error case
16. Example error responses: `Not found / needs verification`
17. Business rules: Frontend docs page, load spec từ `/api-docs/openapi.json`
18. Database interaction liên quan: Không có
19. Stored procedure / table / view / trigger liên quan: Không có
20. Audit / logging behavior nếu có: `morgan` request log
21. Security notes: Swagger asset load từ `unpkg.com`; nếu môi trường không có internet thì UI có thể render lỗi
22. Field visibility notes theo role: Không áp dụng

### 4.2. Auth Module

#### 4.2.1. Login

1. Endpoint name: Login
2. Method: `POST`
3. Full path: `/api/auth/login`
4. Mục đích nghiệp vụ: Xác thực user và cấp access token + refresh token
5. Role được phép gọi: Public
6. Middleware / auth / validation áp dụng: Validation `loginSchema`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "username": "string",
  "password": "string"
}
```

11. Validation rules chi tiết:
   - `username`: string, trim, required
   - `password`: string, min length 6, required
12. Example request:

```json
{
  "username": "director01",
  "password": "123456"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "jwt",
    "refreshToken": "jwt",
    "user": {
      "employeeId": "EM00001",
      "username": "director01",
      "fullName": "Director User",
      "role": "Director",
      "departmentId": "D004"
    }
  },
  "meta": null
}
```

14. Example success response:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "<jwt_access_token>",
    "refreshToken": "<jwt_refresh_token>",
    "user": {
      "employeeId": "EM00001",
      "username": "director01",
      "fullName": "Director User",
      "role": "Director",
      "departmentId": "D004"
    }
  },
  "meta": null
}
```

15. Error cases:
   - `400`: validation fail
   - `401`: invalid credentials / inactive account
   - `500`: SQL/connectivity issue
16. Example error responses:

```json
{
  "success": false,
  "message": "\"password\" length must be at least 6 characters long"
}
```

```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

17. Business rules:
   - Account phải tồn tại
   - `Account.IsActive = 1`
   - `AccountStatus = 'ACTIVE'`
   - Password verify bằng bcrypt
18. Database interaction liên quan:
   - Controller: `auth.controller.js#login`
   - Service: `auth.service.js#login`
   - Repository: `auth.repository.js#findAccountByUsername`
   - Audit insert qua `auditRepository.createLog`
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Auth_GetAccountByUsername`
   - `sp_AuditLog_Create`
   - Tables: `Account`, `Employee`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Login success ghi `LOGIN_SUCCESS`
   - Login fail ghi `LOGIN_FAILED`
21. Security notes:
   - Password hash verify ở app, không dùng raw password sau login
   - Access token payload chứa `employeeId`, `username`, `role`, `departmentId`
22. Field visibility notes theo role:
   - Response `user` không trả salary hoặc tax data

#### 4.2.2. Refresh Access Token

1. Endpoint name: Refresh Token
2. Method: `POST`
3. Full path: `/api/auth/refresh`
4. Mục đích nghiệp vụ: Cấp access token mới từ refresh token
5. Role được phép gọi: Public
6. Middleware / auth / validation áp dụng: Validation `refreshSchema`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "refreshToken": "string"
}
```

11. Validation rules chi tiết:
   - `refreshToken`: string, required
12. Example request:

```json
{
  "refreshToken": "<jwt_refresh_token>"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "accessToken": "jwt"
  },
  "meta": null
}
```

14. Example success response:

```json
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "accessToken": "<new_jwt_access_token>"
  },
  "meta": null
}
```

15. Error cases:
   - `400`: body thiếu `refreshToken`
   - `401`: refresh token không hợp lệ / hết hạn
16. Example error responses:

```json
{
  "success": false,
  "message": "Invalid refresh token"
}
```

17. Business rules:
   - Chỉ verify chữ ký + expiry của refresh token
   - Không query DB
18. Database interaction liên quan: Không có
19. Stored procedure / table / view / trigger liên quan: Không có
20. Audit / logging behavior nếu có: Không có audit riêng
21. Security notes:
   - Không có refresh token revocation / rotation
   - Nếu refresh token bị lộ thì dùng được tới hết hạn
22. Field visibility notes theo role: Không áp dụng

### 4.3. Department Module

#### 4.3.1. List Departments

1. Endpoint name: List Departments
2. Method: `GET`
3. Full path: `/api/departments`
4. Mục đích nghiệp vụ: Lấy danh sách phòng ban
5. Role được phép gọi: Mọi user đã auth
6. Middleware / auth / validation áp dụng: `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/departments
Authorization: Bearer <access_token>
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Departments fetched",
  "data": [
    {
      "DepartmentID": "D003",
      "DepartmentName": "Engineering",
      "ManagerID": "EM00005"
    }
  ],
  "meta": null
}
```

14. Example success response:

```json
{
  "success": true,
  "message": "Departments fetched",
  "data": [
    {
      "DepartmentID": "D001",
      "DepartmentName": "Human Resources",
      "ManagerID": "EM00002"
    },
    {
      "DepartmentID": "D002",
      "DepartmentName": "Finance",
      "ManagerID": "EM00004"
    }
  ],
  "meta": null
}
```

15. Error cases:
   - `401`: thiếu token / token invalid
16. Example error responses:

```json
{
  "success": false,
  "message": "Unauthorized"
}
```

17. Business rules: Không có filter theo role
18. Database interaction liên quan: `departmentService.getAll` -> `departmentRepository.findAll`
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Department_List`
   - Table: `Department`
20. Audit / logging behavior nếu có: Không có audit riêng
21. Security notes:
   - `sp_Department_List` được grant cho `PUBLIC`
22. Field visibility notes theo role: Không có khác biệt theo role

#### 4.3.2. Create Department

1. Endpoint name: Create Department
2. Method: `POST`
3. Full path: `/api/departments`
4. Mục đích nghiệp vụ: Tạo phòng ban mới
5. Role được phép gọi: `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `departmentCreateSchema`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "departmentId": "string",
  "departmentName": "string",
  "managerId": "string | null"
}
```

11. Validation rules chi tiết:
   - `departmentId`: required
   - `departmentName`: trim, required
   - `managerId`: allow `null` hoặc empty string
12. Example request:

```json
{
  "departmentId": "D005",
  "departmentName": "Operations",
  "managerId": "EM00005"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Department created",
  "data": {
    "DepartmentID": "D005",
    "DepartmentName": "Operations",
    "ManagerID": "EM00005"
  },
  "meta": null
}
```

14. Example success response: như schema trên
15. Error cases:
   - `400`: validation fail
   - `403`: role không hợp lệ
   - `500`: department đã tồn tại / manager không tồn tại / DB error
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

```json
{
  "success": false,
  "message": "Department already exists."
}
```

17. Business rules:
   - Chỉ HR Manager hoặc Director
   - `managerId` nếu có phải là employee active
18. Database interaction liên quan:
   - `departmentService.create`
   - `departmentRepository.create`
   - audit log create
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Department_Create`
   - `sp_AuditLog_Create`
   - Tables: `Department`, `Employee`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Ghi `CREATE_DEPARTMENT`
21. Security notes:
   - Role check ở service, không nằm trong procedure body
22. Field visibility notes theo role:
   - Không có field-level variant

#### 4.3.3. Update Department

1. Endpoint name: Update Department
2. Method: `PUT`
3. Full path: `/api/departments/:id`
4. Mục đích nghiệp vụ: Cập nhật tên phòng ban hoặc manager
5. Role được phép gọi: `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `departmentUpdateSchema`
7. Path params:
   - `id`: `string`, department id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "departmentName": "string?",
  "managerId": "string | null"
}
```

11. Validation rules chi tiết:
   - Ít nhất 1 field
   - `departmentName`: optional trim string
   - `managerId`: optional, allow `null` / empty
12. Example request:

```json
{
  "departmentName": "Engineering and Platform",
  "managerId": "EM00005"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Department updated",
  "data": {
    "DepartmentID": "D003",
    "DepartmentName": "Engineering and Platform",
    "ManagerID": "EM00005"
  },
  "meta": null
}
```

14. Example success response: như schema trên
15. Error cases:
   - `400`: body rỗng
   - `403`: role không hợp lệ
   - `404`: department không tồn tại
   - `500`: manager invalid / DB error
16. Example error responses:

```json
{
  "success": false,
  "message": "Department not found"
}
```

17. Business rules:
   - Có thể update từng field
18. Database interaction liên quan: service update -> repository update -> audit create
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Department_Update`
   - `sp_AuditLog_Create`
   - Tables: `Department`, `Employee`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Ghi `UPDATE_DEPARTMENT`
21. Security notes:
   - SQL error custom không map về 4xx
22. Field visibility notes theo role: Không áp dụng

#### 4.3.4. Delete Department

1. Endpoint name: Delete Department
2. Method: `DELETE`
3. Full path: `/api/departments/:id`
4. Mục đích nghiệp vụ: Xóa phòng ban
5. Role được phép gọi: `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`; không có validation schema riêng cho path param
7. Path params:
   - `id`: `string`
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
DELETE /api/departments/D005
Authorization: Bearer <access_token>
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Department deleted",
  "data": null,
  "meta": null
}
```

14. Example success response: như schema trên
15. Error cases:
   - `403`: role không hợp lệ
   - `500`: department còn employee active / DB error
16. Example error responses:

```json
{
  "success": false,
  "message": "Cannot delete department with active employees."
}
```

17. Business rules:
   - Không xóa được department còn employee active
18. Database interaction liên quan: service delete -> repository delete -> audit create
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Department_Delete`
   - `sp_AuditLog_Create`
   - Tables: `Department`, `Employee`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Ghi `DELETE_DEPARTMENT`
21. Security notes:
   - Service không kiểm tra tồn tại trước khi delete; có thể trả success dù id không tồn tại
22. Field visibility notes theo role: Không áp dụng

### 4.4. HR Request Module

#### 4.4.1. Create HR Request

1. Endpoint name: Create HR Request
2. Method: `POST`
3. Full path: `/api/hr-requests`
4. Mục đích nghiệp vụ: HR Staff tạo request onboard employee mới
5. Role được phép gọi: `HR Staff`
6. Middleware / auth / validation áp dụng: `protect`, validation `hrRequestCreateSchema`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "requestType": "CREATE_EMPLOYEE",
  "payload": {
    "fullName": "string",
    "gender": "string | null",
    "dateOfBirth": "YYYY-MM-DD",
    "phoneNumber": "string",
    "taxId": "string",
    "departmentId": "string",
    "positionId": 1,
    "username": "string",
    "password": "string",
    "role": "Employee | Manager | HR Staff | HR Manager | Finance Staff"
  }
}
```

11. Validation rules chi tiết:
   - `requestType`: chỉ `CREATE_EMPLOYEE`
   - `payload.fullName`: required
   - `payload.gender`: allow empty/null
   - `payload.dateOfBirth`: date, required
   - `payload.phoneNumber`: required
   - `payload.taxId`: required
   - `payload.departmentId`: required
   - `payload.positionId`: integer, required
   - `payload.username`: required
   - `payload.password`: string, min 6, required
   - `payload.role`: enum `Employee|Manager|HR Staff|HR Manager|Finance Staff`
12. Example request:

```json
{
  "requestType": "CREATE_EMPLOYEE",
  "payload": {
    "fullName": "Pending Employee User",
    "gender": "Male",
    "dateOfBirth": "2000-04-10",
    "phoneNumber": "0901999991",
    "taxId": "777777777",
    "departmentId": "D003",
    "positionId": 1,
    "username": "pendingemp01",
    "password": "123456",
    "role": "Employee"
  }
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "HR request created",
  "data": {
    "RequestID": 4,
    "RequestType": "CREATE_EMPLOYEE",
    "Status": "PENDING",
    "RequesterID": "EM00003",
    "ApproverID": null,
    "RequestPayload": "{\"fullName\":\"...\",\"password\":null}",
    "CreatedAt": "2026-04-21T14:00:00.000Z",
    "ApprovedAt": null,
    "RejectionReason": null
  },
  "meta": null
}
```

14. Example success response:
Synthetic but schema-correct; password trong `RequestPayload` đọc ra đã bị SQL mask

15. Error cases:
   - `400`: validation fail
   - `403`: không phải HR Staff
   - `500`: SQL reject do requestType sai hoặc actor role mismatch
16. Example error responses:

```json
{
  "success": false,
  "message": "Only HR Staff can create HR request"
}
```

17. Business rules:
   - Chỉ HR Staff tạo
   - Chỉ hỗ trợ `CREATE_EMPLOYEE`
   - Request sau khi tạo có status `PENDING`
18. Database interaction liên quan:
   - service create -> repository create -> audit create
19. Stored procedure / table / view / trigger liên quan:
   - `sp_HRRequest_Create`
   - `sp_AuditLog_Create`
   - Tables: `HR_Request`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Ghi `CREATE_HR_REQUEST`
21. Security notes:
   - `Observed in SQL`: read response đã mask password
   - `Observed in SQL`: raw password vẫn được lưu trong `HR_Request.RequestPayload`
22. Field visibility notes theo role:
   - Không có role variant ở response; endpoint chỉ dành cho HR Staff

#### 4.4.2. List HR Requests

1. Endpoint name: List HR Requests
2. Method: `GET`
3. Full path: `/api/hr-requests`
4. Mục đích nghiệp vụ: Xem danh sách request onboarding
5. Role được phép gọi: `HR Staff`, `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/hr-requests
Authorization: Bearer <access_token>
```

13. Success response schema:

```json
{
  "success": true,
  "message": "HR requests fetched",
  "data": [
    {
      "RequestID": 1,
      "RequestType": "CREATE_EMPLOYEE",
      "Status": "PENDING",
      "RequesterID": "EM00003",
      "ApproverID": null,
      "RequestPayload": "{\"fullName\":\"Pending Employee User\",\"password\":null}",
      "CreatedAt": "2026-04-21T14:00:00.000Z",
      "ApprovedAt": null,
      "RejectionReason": null
    }
  ],
  "meta": null
}
```

14. Example success response:
Observed from tests: HR Staff seed user thấy 3 request; password không có trong JSON parse của `RequestPayload`

15. Error cases:
   - `403`: role không hợp lệ
   - `401`: token invalid
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

17. Business rules:
   - HR Staff chỉ thấy request do mình tạo
   - HR Manager và Director thấy tất cả
18. Database interaction liên quan: service getAll -> repository findAllByScope
19. Stored procedure / table / view / trigger liên quan:
   - `sp_HRRequest_ListByScope`
   - Table: `HR_Request`
20. Audit / logging behavior nếu có: Không có audit riêng cho read
21. Security notes:
   - Password trong `RequestPayload` được set `null` bằng `JSON_MODIFY`
22. Field visibility notes theo role:
   - Row-level restriction khác nhau theo role

#### 4.4.3. Get HR Request By ID

1. Endpoint name: Get HR Request By ID
2. Method: `GET`
3. Full path: `/api/hr-requests/:id`
4. Mục đích nghiệp vụ: Xem chi tiết một request onboarding
5. Role được phép gọi: `HR Staff`, `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`; không có schema validate path param
7. Path params:
   - `id`: `int`
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có explicit Joi cho `id`
12. Example request:

```http
GET /api/hr-requests/1
Authorization: Bearer <access_token>
```

13. Success response schema: cùng shape với một item của list HR requests
14. Example success response:

```json
{
  "success": true,
  "message": "HR request fetched",
  "data": {
    "RequestID": 1,
    "RequestType": "CREATE_EMPLOYEE",
    "Status": "PENDING",
    "RequesterID": "EM00003",
    "ApproverID": null,
    "RequestPayload": "{\"fullName\":\"Pending Employee User\",\"password\":null}",
    "CreatedAt": "2026-04-21T14:00:00.000Z",
    "ApprovedAt": null,
    "RejectionReason": null
  },
  "meta": null
}
```

15. Error cases:
   - `404`: request không thấy trong scope
   - `500`: role không hợp lệ nhưng SQL ném lỗi trước khi service check
16. Example error responses:

```json
{
  "success": false,
  "message": "HR request not found"
}
```

17. Business rules:
   - HR Staff chỉ xem request của mình
18. Database interaction liên quan: service getById -> repository findByIdByScope
19. Stored procedure / table / view / trigger liên quan:
   - `sp_HRRequest_GetByIdByScope`
   - Table: `HR_Request`
20. Audit / logging behavior nếu có: Không có audit riêng
21. Security notes:
   - Password bị mask ở SQL
22. Field visibility notes theo role:
   - Row-level restriction khác nhau theo role

### 4.5. Approval Module

#### 4.5.1. List Pending Approvals

1. Endpoint name: List Pending Approvals
2. Method: `GET`
3. Full path: `/api/approvals/pending`
4. Mục đích nghiệp vụ: Director xem danh sách request chờ duyệt
5. Role được phép gọi: `Director`
6. Middleware / auth / validation áp dụng: `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/approvals/pending
Authorization: Bearer <access_token>
```

13. Success response schema: danh sách object giống HR request item, chỉ gồm record `Status = PENDING`
14. Example success response:

```json
{
  "success": true,
  "message": "Pending requests fetched",
  "data": [
    {
      "RequestID": 1,
      "RequestType": "CREATE_EMPLOYEE",
      "Status": "PENDING",
      "RequesterID": "EM00003",
      "ApproverID": null,
      "RequestPayload": "{\"fullName\":\"Pending Employee User\",\"password\":null}",
      "CreatedAt": "2026-04-21T14:00:00.000Z",
      "ApprovedAt": null,
      "RejectionReason": null
    }
  ],
  "meta": null
}
```

15. Error cases:
   - `403`: không phải Director
16. Example error responses:

```json
{
  "success": false,
  "message": "Only Director can access pending approvals"
}
```

17. Business rules: Chỉ lấy request đang `PENDING`
18. Database interaction liên quan: service getPending -> repository findPendingRequests
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Approval_ListPending_ForDirector`
   - Table: `HR_Request`
20. Audit / logging behavior nếu có: Không có audit riêng cho read
21. Security notes: Password trong payload vẫn bị mask ở read path
22. Field visibility notes theo role: Chỉ Director gọi được

#### 4.5.2. Approve Create Employee Request

1. Endpoint name: Approve HR Request
2. Method: `POST`
3. Full path: `/api/approvals/:requestId/approve`
4. Mục đích nghiệp vụ: Director duyệt request và cấu hình salary ban đầu cho nhân viên mới
5. Role được phép gọi: `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `approvalApproveSchema`
7. Path params:
   - `requestId`: `int`
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "baseSalary": 10000000,
  "salaryCoefficient": 1.1,
  "positionCoefficient": 1.0,
  "allowance": 500000,
  "formulaVersion": "v1"
}
```

11. Validation rules chi tiết:
   - `baseSalary`: number, positive, required
   - `salaryCoefficient`: number, positive, required
   - `positionCoefficient`: number, positive, required
   - `allowance`: number, min `0`, required
   - `formulaVersion`: string, default `v1`
12. Example request:

```json
{
  "baseSalary": 10000000,
  "salaryCoefficient": 1.1,
  "positionCoefficient": 1.0,
  "allowance": 500000,
  "formulaVersion": "v1"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "HR request approved",
  "data": {
    "EmployeeID": "EM00007",
    "Username": "pendingemp01",
    "Role": "Employee",
    "DepartmentID": "D003",
    "FinalSalary": 11500000
  },
  "meta": null
}
```

14. Example success response:
Synthetic but schema-correct theo `sp_Approval_ApproveCreateEmployee`

15. Error cases:
   - `400`: validation fail
   - `403`: không phải Director
   - `404`: request không tồn tại / không pending
   - `500`: username duplicate, department invalid, position invalid, SQL transaction fail
16. Example error responses:

```json
{
  "success": false,
  "message": "Only Director can approve request"
}
```

```json
{
  "success": false,
  "message": "HR request not found"
}
```

17. Business rules:
   - Director nhập salary formula inputs, không nhập final salary
   - `FinalSalary` được suy ra bởi SQL
   - Tạo `Employee`, `Account`, `EmployeeSalaryConfig`, `EmployeeSalaryResult`
   - Update `HR_Request.Status = APPROVED`
18. Database interaction liên quan:
   - service đọc raw request payload để hash password
   - repository mở outer transaction rồi execute proc approve
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Approval_GetRequestForDirector`
   - `sp_Approval_ApproveCreateEmployee`
   - `sp_Salary_UpsertCore`
   - `sp_AuditLog_Create`
   - Tables: `HR_Request`, `Employee`, `Account`, `EmployeeSalaryConfig`, `EmployeeSalaryResult`, `Audit_Log`, `Department`, `Position`
20. Audit / logging behavior nếu có:
   - App ghi `APPROVE_HR_REQUEST`
21. Security notes:
   - Password được hash ở app bằng bcrypt trước khi insert account
   - Raw password nằm trong `HR_Request.RequestPayload` để phục vụ approval flow
22. Field visibility notes theo role:
   - Endpoint chỉ Director gọi được

#### 4.5.3. Reject HR Request

1. Endpoint name: Reject HR Request
2. Method: `POST`
3. Full path: `/api/approvals/:requestId/reject`
4. Mục đích nghiệp vụ: Director từ chối request onboarding
5. Role được phép gọi: `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `approvalRejectSchema`
7. Path params:
   - `requestId`: `int`
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "rejectionReason": "string"
}
```

11. Validation rules chi tiết:
   - `rejectionReason`: trim string, required
12. Example request:

```json
{
  "rejectionReason": "Missing supporting documents"
}
```

13. Success response schema:

```json
{
  "success": true,
  "message": "HR request rejected",
  "data": {
    "requestId": 3,
    "status": "REJECTED"
  },
  "meta": null
}
```

14. Example success response: như schema trên
15. Error cases:
   - `400`: validation fail
   - `403`: không phải Director
   - `500`: request không pending / SQL error
16. Example error responses:

```json
{
  "success": false,
  "message": "Request not found or not pending."
}
```

17. Business rules:
   - Chỉ reject request đang pending
18. Database interaction liên quan: service reject -> repository reject -> audit create
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Approval_RejectRequest`
   - `sp_AuditLog_Create`
   - Tables: `HR_Request`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - App ghi `REJECT_HR_REQUEST`
21. Security notes:
   - Không có transaction multi-step phức tạp
22. Field visibility notes theo role: Chỉ Director

### 4.6. Employee Module

#### 4.6.1. List Employees

1. Endpoint name: List Employees
2. Method: `GET`
3. Full path: `/api/employees`
4. Mục đích nghiệp vụ: Liệt kê nhân sự theo scope và field visibility của role đang gọi
5. Role được phép gọi: Tất cả user đã auth
6. Middleware / auth / validation áp dụng: `protect`; role-to-procedure map ở `employee.rbac.js`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/employees
Authorization: Bearer <access_token>
```

13. Success response schema:
   - Wrapper chuẩn
   - `data` là array object, shape thay đổi theo role
14. Example success response:

Director variant:

```json
{
  "success": true,
  "message": "Employees fetched",
  "data": [
    {
      "EmployeeID": "EM00006",
      "FullName": "Employee User",
      "Gender": "Female",
      "DateOfBirth": "1998-11-25",
      "PhoneNumber": "0901000006",
      "TaxID": "666666666",
      "DepartmentID": "D003",
      "DepartmentName": "Engineering",
      "PositionID": 1,
      "EmploymentStatus": "ACTIVE",
      "IsActive": true,
      "CreatedAt": "2026-04-21T14:00:00.000Z",
      "BaseSalary": "10000000",
      "SalaryCoefficient": "1.10",
      "PositionCoefficient": "1.00",
      "Allowance": "500000",
      "FinalSalary": "11500000"
    }
  ],
  "meta": null
}
```

Finance variant:

```json
{
  "success": true,
  "message": "Employees fetched",
  "data": [
    {
      "EmployeeID": "EM00005",
      "FullName": null,
      "Gender": null,
      "DateOfBirth": null,
      "PhoneNumber": null,
      "TaxID": "555555555",
      "DepartmentID": null,
      "DepartmentName": null,
      "PositionID": null,
      "EmploymentStatus": null,
      "IsActive": null,
      "CreatedAt": null,
      "Allowance": "3000000",
      "FinalSalary": "40800000"
    }
  ],
  "meta": null
}
```

15. Error cases:
   - `401`: token invalid
   - `403`: role không map được vào procedure
   - `500`: SQL error
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

17. Business rules:
   - Employee: thấy employee active cùng department
   - Manager: thấy employee active thuộc department mình manage
   - HR Staff: thấy toàn bộ employee active trừ `D001`
   - HR Manager: thấy toàn bộ employee active
   - Finance: thấy toàn bộ employee active, profile ngoài department Finance bị mask
   - Director: thấy toàn bộ employee active + salary config/result
18. Database interaction liên quan:
   - service getAll -> repository findAllByRoleScope -> SQL proc theo role
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Employee_GetList_ForEmployee`
   - `sp_Employee_GetList_ForManager`
   - `sp_Employee_GetList_ForHRStaff`
   - `sp_Employee_GetList_ForHRManager`
   - `sp_Employee_GetList_ForFinance`
   - `sp_Employee_GetList_ForDirector`
   - Tables: `Employee`, `Department`, `EmployeeSalaryConfig`, `EmployeeSalaryResult`
20. Audit / logging behavior nếu có: Không có audit cho read
21. Security notes:
   - `Observed in SQL`: row-level filtering ở procedure
   - `Observed in SQL`: dữ liệu nhạy cảm được decrypt trong proc rồi trả về API theo role
22. Field visibility notes theo role:
   - Employee/HR Staff/HR Manager: không có salary fields
   - Manager: có `Allowance`, `FinalSalary`
   - Finance: không có `BaseSalary`, `SalaryCoefficient`, `PositionCoefficient`
   - Director: có full salary fields

#### 4.6.2. Get Employee By ID

1. Endpoint name: Get Employee By ID
2. Method: `GET`
3. Full path: `/api/employees/:id`
4. Mục đích nghiệp vụ: Lấy chi tiết employee theo scope của role
5. Role được phép gọi: Tất cả user đã auth
6. Middleware / auth / validation áp dụng: `protect`; role-to-procedure map ở `employee.rbac.js`
7. Path params:
   - `id`: `string`, employee id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có Joi cho path param
12. Example request:

```http
GET /api/employees/EM00006
Authorization: Bearer <access_token>
```

13. Success response schema:
   - Wrapper chuẩn
   - `data` là 1 employee object, field set tùy role
14. Example success response:

Manager variant:

```json
{
  "success": true,
  "message": "Employee fetched",
  "data": {
    "EmployeeID": "EM00006",
    "FullName": "Employee User",
    "Gender": "Female",
    "DateOfBirth": "1998-11-25",
    "PhoneNumber": "0901000006",
    "TaxID": "666666666",
    "DepartmentID": "D003",
    "DepartmentName": "Engineering",
    "PositionID": 1,
    "EmploymentStatus": "ACTIVE",
    "IsActive": true,
    "CreatedAt": "2026-04-21T14:00:00.000Z",
    "Allowance": "500000",
    "FinalSalary": "11500000"
  },
  "meta": null
}
```

15. Error cases:
   - `404`: employee không tồn tại hoặc ngoài scope
   - `401`: token invalid
16. Example error responses:

```json
{
  "success": false,
  "message": "Employee not found or access denied"
}
```

17. Business rules:
   - Scope giống list endpoint
18. Database interaction liên quan: service getById -> repository findByIdScoped
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Employee_GetById_ForEmployee`
   - `sp_Employee_GetById_ForManager`
   - `sp_Employee_GetById_ForHRStaff`
   - `sp_Employee_GetById_ForHRManager`
   - `sp_Employee_GetById_ForFinance`
   - `sp_Employee_GetById_ForDirector`
20. Audit / logging behavior nếu có: Không có audit cho read
21. Security notes:
   - Finance variant mask profile ngoài Finance
22. Field visibility notes theo role:
   - Tương tự list endpoint

#### 4.6.3. Update Employee

1. Endpoint name: Update Employee
2. Method: `PUT`
3. Full path: `/api/employees/:id`
4. Mục đích nghiệp vụ: Cập nhật profile employee, không bao gồm salary config
5. Role được phép gọi: `Employee`, `HR Staff`, `HR Manager`
6. Middleware / auth / validation áp dụng: `protect`, validation `employeeUpdateSchema`, field sanitization ở `sanitizeEmployeeUpdatePayload`
7. Path params:
   - `id`: `string`, employee id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "fullName": "string?",
  "gender": "string | null",
  "dateOfBirth": "YYYY-MM-DD?",
  "phoneNumber": "string?",
  "departmentId": "string?",
  "positionId": 2,
  "employmentStatus": "string?",
  "isActive": true
}
```

11. Validation rules chi tiết:
   - Ít nhất 1 field
   - `positionId`: integer nếu có
   - `isActive`: boolean nếu có
   - Sau Joi còn có field whitelist theo role:
     - Employee: `fullName`, `gender`, `dateOfBirth`, `phoneNumber`
     - HR Staff: giống Employee
     - HR Manager: thêm `departmentId`, `positionId`, `employmentStatus`, `isActive`
12. Example request:

Employee self-update:

```json
{
  "fullName": "Employee User Updated",
  "phoneNumber": "0901222333"
}
```

HR Manager update:

```json
{
  "departmentId": "D002",
  "positionId": 2,
  "employmentStatus": "ACTIVE",
  "isActive": true
}
```

13. Success response schema:
   - Wrapper chuẩn
   - `data` là employee object sau update, nhưng vẫn theo field visibility của role caller
14. Example success response:

```json
{
  "success": true,
  "message": "Employee updated",
  "data": {
    "EmployeeID": "EM00006",
    "FullName": "Employee User Updated",
    "Gender": "Female",
    "DateOfBirth": "1998-11-25",
    "PhoneNumber": "0901222333",
    "TaxID": "666666666",
    "DepartmentID": "D003",
    "DepartmentName": "Engineering",
    "PositionID": 1,
    "EmploymentStatus": "ACTIVE",
    "IsActive": true,
    "CreatedAt": "2026-04-21T14:00:00.000Z"
  },
  "meta": null
}
```

15. Error cases:
   - `400`: body fail Joi hoặc không có field được phép
   - `403`: Employee update người khác / role không hợp lệ
   - `404`: employee không tồn tại
   - `500`: SQL error
16. Example error responses:

```json
{
  "success": false,
  "message": "No allowed fields to update"
}
```

```json
{
  "success": false,
  "message": "Employee can only update own profile"
}
```

17. Business rules:
   - Employee chỉ update bản thân
   - Salary không update ở đây
   - HR Staff không update employee thuộc `D001`
18. Database interaction liên quan:
   - service lấy current record, sanitize payload, update proc theo role, đọc lại visible record, rồi audit
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Employee_UpdateProfile_ForEmployee`
   - `sp_Employee_UpdateProfile_ForHRStaff`
   - `sp_Employee_UpdateProfile_ForHRManager`
   - `sp_AuditLog_Create`
   - Tables: `Employee`, `Department`, `Position`, `Audit_Log`
20. Audit / logging behavior nếu có:
   - Ghi `UPDATE_EMPLOYEE`
   - `oldValues`/`newValues` theo view của role caller, không phải full DB row
21. Security notes:
   - App chủ động loại bỏ field không được phép
22. Field visibility notes theo role:
   - Response sau update vẫn bị giới hạn theo role caller

### 4.7. Salary Module

#### 4.7.1. List Salaries

1. Endpoint name: List Salaries
2. Method: `GET`
3. Full path: `/api/salaries`
4. Mục đích nghiệp vụ: Lấy dữ liệu salary theo role-sensitive visibility
5. Role được phép gọi: `Finance Staff`, `Director`
6. Middleware / auth / validation áp dụng: `protect`, service role check, procedure map ở `salary.rbac.js`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/salaries
Authorization: Bearer <access_token>
```

13. Success response schema:
   - Wrapper chuẩn
   - `data` array object, field set theo role
14. Example success response:

Director variant:

```json
{
  "success": true,
  "message": "Salaries fetched",
  "data": [
    {
      "EmployeeID": "EM00006",
      "FullName": "Employee User",
      "DepartmentID": "D003",
      "DepartmentName": "Engineering",
      "PositionID": 1,
      "TaxID": "666666666",
      "BaseSalary": "10000000",
      "SalaryCoefficient": "1.10",
      "PositionCoefficient": "1.00",
      "Allowance": "500000",
      "FinalSalary": "11500000",
      "FormulaVersion": "v1",
      "ApprovedBy": "EM00001",
      "SalaryUpdatedAt": "2026-04-21T14:00:00.000Z",
      "SalaryCalculatedAt": "2026-04-21T14:00:00.000Z"
    }
  ],
  "meta": null
}
```

Finance variant:

```json
{
  "success": true,
  "message": "Salaries fetched",
  "data": [
    {
      "EmployeeID": "EM00005",
      "FullName": null,
      "DepartmentID": null,
      "DepartmentName": null,
      "TaxID": "555555555",
      "Allowance": "3000000",
      "FinalSalary": "40800000",
      "FormulaVersion": "v1",
      "SalaryUpdatedAt": "2026-04-21T14:00:00.000Z",
      "SalaryCalculatedAt": "2026-04-21T14:00:00.000Z"
    }
  ],
  "meta": null
}
```

15. Error cases:
   - `403`: role không hợp lệ
   - `401`: token invalid
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

17. Business rules:
   - Finance chỉ read
   - Director read full formula inputs + final salary
18. Database interaction liên quan: service getList -> repository findList
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Salary_GetList_ForFinance`
   - `sp_Salary_GetList_ForDirector`
   - Tables: `Employee`, `Department`, `EmployeeSalaryConfig`, `EmployeeSalaryResult`
20. Audit / logging behavior nếu có: Không có audit cho read
21. Security notes:
   - Final salary luôn là dữ liệu đọc ra từ encrypted store
22. Field visibility notes theo role:
   - Finance: không có `BaseSalary`, `SalaryCoefficient`, `PositionCoefficient`, `ApprovedBy`
   - Director: có full fields

#### 4.7.2. Get Salary By Employee ID

1. Endpoint name: Get Salary By Employee ID
2. Method: `GET`
3. Full path: `/api/salaries/:id`
4. Mục đích nghiệp vụ: Lấy chi tiết salary của một employee
5. Role được phép gọi: `Finance Staff`, `Director`
6. Middleware / auth / validation áp dụng: `protect`
7. Path params:
   - `id`: `string`, employee id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có Joi path validation
12. Example request:

```http
GET /api/salaries/EM00006
Authorization: Bearer <access_token>
```

13. Success response schema: một record salary theo role
14. Example success response:

```json
{
  "success": true,
  "message": "Salary fetched",
  "data": {
    "EmployeeID": "EM00006",
    "FullName": "Employee User",
    "DepartmentID": "D003",
    "DepartmentName": "Engineering",
    "PositionID": 1,
    "TaxID": "666666666",
    "BaseSalary": "10000000",
    "SalaryCoefficient": "1.10",
    "PositionCoefficient": "1.00",
    "Allowance": "500000",
    "FinalSalary": "11500000",
    "FormulaVersion": "v1",
    "ApprovedBy": "EM00001",
    "SalaryUpdatedAt": "2026-04-21T14:00:00.000Z",
    "SalaryCalculatedAt": "2026-04-21T14:00:00.000Z"
  },
  "meta": null
}
```

15. Error cases:
   - `403`: role không hợp lệ
   - `404`: không thấy salary
16. Example error responses:

```json
{
  "success": false,
  "message": "Salary not found"
}
```

17. Business rules:
   - Finance có thể xem mọi employee nhưng profile ngoài Finance bị mask
18. Database interaction liên quan: service getByEmployeeId -> repository findByEmployeeId
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Salary_GetByEmployeeId_ForFinance`
   - `sp_Salary_GetByEmployeeId_ForDirector`
20. Audit / logging behavior nếu có: Không có audit cho read
21. Security notes: Same as list salary
22. Field visibility notes theo role: Same as list salary

#### 4.7.3. Update Salary By Director

1. Endpoint name: Update Salary
2. Method: `PUT`
3. Full path: `/api/salaries/:id`
4. Mục đích nghiệp vụ: Director cập nhật salary formula inputs cho employee
5. Role được phép gọi: `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `salaryUpdateSchema`
7. Path params:
   - `id`: `string`, employee id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
   - `Content-Type: application/json`
10. Request body schema:

```json
{
  "baseSalary": 15000000,
  "salaryCoefficient": 1.25,
  "positionCoefficient": 1.1,
  "allowance": 700000,
  "formulaVersion": "v2"
}
```

11. Validation rules chi tiết:
   - `baseSalary`: positive, required
   - `salaryCoefficient`: positive, required
   - `positionCoefficient`: positive, required
   - `allowance`: min `0`, required
   - `formulaVersion`: optional, allow empty/null, default `v1`
12. Example request:

```json
{
  "baseSalary": 15000000,
  "salaryCoefficient": 1.25,
  "positionCoefficient": 1.1,
  "allowance": 700000,
  "formulaVersion": "v2"
}
```

13. Success response schema:
   - Wrapper chuẩn
   - `data` là Director salary record sau update
14. Example success response:

```json
{
  "success": true,
  "message": "Salary updated",
  "data": {
    "EmployeeID": "EM00006",
    "FullName": "Employee User",
    "DepartmentID": "D003",
    "DepartmentName": "Engineering",
    "PositionID": 1,
    "TaxID": "666666666",
    "BaseSalary": "15000000",
    "SalaryCoefficient": "1.25",
    "PositionCoefficient": "1.10",
    "Allowance": "700000",
    "FinalSalary": "21325000.00",
    "FormulaVersion": "v2",
    "ApprovedBy": "EM00001",
    "SalaryUpdatedAt": "2026-04-21T14:00:00.000Z",
    "SalaryCalculatedAt": "2026-04-21T14:00:00.000Z"
  },
  "meta": null
}
```

15. Error cases:
   - `400`: validation fail
   - `403`: không phải Director
   - `404`: salary/employee không thấy
   - `500`: SQL error
16. Example error responses:

```json
{
  "success": false,
  "message": "\"baseSalary\" must be a positive number"
}
```

17. Business rules:
   - Director nhập formula inputs
   - Final salary tính bởi SQL, không nhập trực tiếp
   - Upsert cả `EmployeeSalaryConfig` và `EmployeeSalaryResult`
18. Database interaction liên quan:
   - service updateForDirector -> repository updateForDirector -> proc update
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Salary_Update_ForDirector`
   - `sp_Salary_UpsertCore`
   - `sp_AuditLog_Create`
   - Tables: `EmployeeSalaryConfig`, `EmployeeSalaryResult`, `Audit_Log`, `Employee`
20. Audit / logging behavior nếu có:
   - Audit `UPDATE_SALARY` được ghi trong SQL procedure
21. Security notes:
   - `Observed in SQL`: transaction + `XACT_ABORT ON`
   - Director là role duy nhất có quyền write salary
22. Field visibility notes theo role:
   - Chỉ Director gọi được và nhận full salary record

### 4.8. Finance Module

#### 4.8.1. Get Payroll List

1. Endpoint name: Get Payroll List
2. Method: `GET`
3. Full path: `/api/finance/payroll`
4. Mục đích nghiệp vụ: Backward-compatible alias cho salary list
5. Role được phép gọi: `Finance Staff`, `Director`
6. Middleware / auth / validation áp dụng: `protect`
7. Path params: Không có
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/finance/payroll
Authorization: Bearer <access_token>
```

13. Success response schema: giống `GET /api/salaries`
14. Example success response: cùng shape với salary list theo role
15. Error cases:
   - `403`: role không hợp lệ
   - `401`: token invalid
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

17. Business rules: Alias read-only
18. Database interaction liên quan:
   - `financeService.getPayroll` gọi `financeRepository.findPayroll`
   - `financeRepository` delegate sang `salaryRepository.findList`
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Salary_GetList_ForFinance`
   - `sp_Salary_GetList_ForDirector`
20. Audit / logging behavior nếu có: Không có
21. Security notes: Behavior phải coi như salary endpoint
22. Field visibility notes theo role: Tương tự salary list

#### 4.8.2. Get Payroll Detail

1. Endpoint name: Get Payroll Detail
2. Method: `GET`
3. Full path: `/api/finance/payroll/:id`
4. Mục đích nghiệp vụ: Backward-compatible alias cho salary detail
5. Role được phép gọi: `Finance Staff`, `Director`
6. Middleware / auth / validation áp dụng: `protect`
7. Path params:
   - `id`: `string`, employee id
8. Query params: Không có
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết: Không có
12. Example request:

```http
GET /api/finance/payroll/EM00006
Authorization: Bearer <access_token>
```

13. Success response schema: giống `GET /api/salaries/:id`
14. Example success response: cùng shape với salary detail theo role
15. Error cases:
   - `403`: role không hợp lệ
   - `404`: payroll không thấy
16. Example error responses:

```json
{
  "success": false,
  "message": "Payroll not found"
}
```

17. Business rules: Alias read-only
18. Database interaction liên quan:
   - service -> finance repo -> salary repo -> salary proc
19. Stored procedure / table / view / trigger liên quan:
   - `sp_Salary_GetByEmployeeId_ForFinance`
   - `sp_Salary_GetByEmployeeId_ForDirector`
20. Audit / logging behavior nếu có: Không có
21. Security notes: Behavior giống salary detail
22. Field visibility notes theo role: Tương tự salary detail

### 4.9. Audit Module

#### 4.9.1. List Audit Logs

1. Endpoint name: List Audit Logs
2. Method: `GET`
3. Full path: `/api/audit-logs`
4. Mục đích nghiệp vụ: Xem audit trail hệ thống
5. Role được phép gọi: `HR Manager`, `Director`
6. Middleware / auth / validation áp dụng: `protect`, validation `auditQuerySchema`
7. Path params: Không có
8. Query params:
   - `actorId`: string optional
   - `actorRole`: string optional
   - `actionType`: string optional
   - `tableName`: string optional
   - `startDate`: date optional
   - `endDate`: date optional
   - `page`: integer min 1, default 1
   - `limit`: integer 1..100, default 20
9. Request headers:
   - `Authorization: Bearer <access_token>`
10. Request body schema: Không có
11. Validation rules chi tiết:
   - `page >= 1`
   - `limit` từ `1` tới `100`
12. Example request:

```http
GET /api/audit-logs?actionType=UPDATE_SALARY&page=1&limit=20
Authorization: Bearer <access_token>
```

13. Success response schema:

```json
{
  "success": true,
  "message": "Audit logs fetched",
  "data": [
    {
      "LogID": 1,
      "ActorID": "EM00001",
      "ActorRole": "Director",
      "ActionType": "UPDATE_SALARY",
      "TableName": "EmployeeSalaryConfig",
      "RecordID": "EM00006",
      "OldValues": "{\"EmployeeID\":\"EM00006\"}",
      "NewValues": "{\"EmployeeID\":\"EM00006\"}",
      "Timestamp": "2026-04-21T14:00:00.000Z"
    }
  ],
  "meta": null
}
```

14. Example success response: synthetic but schema-correct
15. Error cases:
   - `400`: query validation fail
   - `403`: role không hợp lệ
16. Example error responses:

```json
{
  "success": false,
  "message": "Forbidden"
}
```

17. Business rules:
   - Có paging ở SQL nhưng API không trả tổng số record
18. Database interaction liên quan: service getLogs -> repository findAll
19. Stored procedure / table / view / trigger liên quan:
   - `sp_AuditLog_List`
   - Table: `Audit_Log`
20. Audit / logging behavior nếu có: Endpoint chỉ đọc audit log, không tự log việc đọc
21. Security notes:
   - Audit chứa `OldValues`/`NewValues` stringified JSON, có thể chứa dữ liệu nhạy cảm
22. Field visibility notes theo role:
   - Chỉ HR Manager và Director

---

## 5. Database-to-API mapping

| Endpoint | Controller | Service | Repository | SQL object/table/procedure liên quan | Role/security dependency |
| --- | --- | --- | --- | --- | --- |
| `GET /health` | inline in `app.js` | N/A | N/A | None | Public |
| `POST /api/auth/login` | `auth.controller.login` | `authService.login` | `authRepository.findAccountByUsername`, `auditRepository.createLog` | `sp_Auth_GetAccountByUsername`, `sp_AuditLog_Create`, `Account`, `Employee`, `Audit_Log` | Public, account active |
| `POST /api/auth/refresh` | `auth.controller.refresh` | `authService.refresh` | N/A | None | Public, refresh token valid |
| `GET /api/departments` | `department.controller.getAll` | `departmentService.getAll` | `departmentRepository.findAll` | `sp_Department_List`, `Department` | Any authenticated user |
| `POST /api/departments` | `department.controller.create` | `departmentService.create` | `departmentRepository.create`, `auditRepository.createLog` | `sp_Department_Create`, `sp_AuditLog_Create`, `Department`, `Employee`, `Audit_Log` | HR Manager, Director |
| `PUT /api/departments/:id` | `department.controller.update` | `departmentService.update` | `departmentRepository.updateById`, `auditRepository.createLog` | `sp_Department_Update`, `sp_AuditLog_Create`, `Department`, `Employee`, `Audit_Log` | HR Manager, Director |
| `DELETE /api/departments/:id` | `department.controller.remove` | `departmentService.delete` | `departmentRepository.deleteById`, `auditRepository.createLog` | `sp_Department_Delete`, `sp_AuditLog_Create`, `Department`, `Employee`, `Audit_Log` | HR Manager, Director |
| `POST /api/hr-requests` | `request.controller.create` | `requestService.create` | `requestRepository.create`, `auditRepository.createLog` | `sp_HRRequest_Create`, `sp_AuditLog_Create`, `HR_Request`, `Audit_Log` | HR Staff only |
| `GET /api/hr-requests` | `request.controller.getAll` | `requestService.getAll` | `requestRepository.findAllByScope` | `sp_HRRequest_ListByScope`, `HR_Request` | HR Staff/HR Manager/Director |
| `GET /api/hr-requests/:id` | `request.controller.getById` | `requestService.getById` | `requestRepository.findByIdByScope` | `sp_HRRequest_GetByIdByScope`, `HR_Request` | HR Staff/HR Manager/Director |
| `GET /api/approvals/pending` | `approval.controller.getPending` | `approvalService.getPending` | `approvalRepository.findPendingRequests` | `sp_Approval_ListPending_ForDirector`, `HR_Request` | Director only |
| `POST /api/approvals/:requestId/approve` | `approval.controller.approve` | `approvalService.approve` | `approvalRepository.findRequestForDirector`, `approvalRepository.approveRequest`, `auditRepository.createLog` | `sp_Approval_GetRequestForDirector`, `sp_Approval_ApproveCreateEmployee`, `sp_Salary_UpsertCore`, `sp_AuditLog_Create`, multiple tables | Director only |
| `POST /api/approvals/:requestId/reject` | `approval.controller.reject` | `approvalService.reject` | `approvalRepository.rejectRequest`, `auditRepository.createLog` | `sp_Approval_RejectRequest`, `sp_AuditLog_Create`, `HR_Request`, `Audit_Log` | Director only |
| `GET /api/employees` | `employee.controller.getAll` | `employeeService.getAll` | `employeeRepository.findAllByRoleScope` | `sp_Employee_GetList_*`, `Employee`, `Department`, salary tables | Role-based field and row scope |
| `GET /api/employees/:id` | `employee.controller.getById` | `employeeService.getById` | `employeeRepository.findByIdScoped` | `sp_Employee_GetById_*`, `Employee`, `Department`, salary tables | Role-based field and row scope |
| `PUT /api/employees/:id` | `employee.controller.update` | `employeeService.update` | `employeeRepository.updateByRole`, `auditRepository.createLog` | `sp_Employee_UpdateProfile_*`, `sp_AuditLog_Create`, `Employee`, `Department`, `Position`, `Audit_Log` | Employee/HR Staff/HR Manager |
| `GET /api/salaries` | `salary.controller.getAll` | `salaryService.getList` | `salaryRepository.findList` | `sp_Salary_GetList_ForFinance`, `sp_Salary_GetList_ForDirector`, salary tables | Finance Staff, Director |
| `GET /api/salaries/:id` | `salary.controller.getById` | `salaryService.getByEmployeeId` | `salaryRepository.findByEmployeeId` | `sp_Salary_GetByEmployeeId_ForFinance`, `sp_Salary_GetByEmployeeId_ForDirector`, salary tables | Finance Staff, Director |
| `PUT /api/salaries/:id` | `salary.controller.updateByDirector` | `salaryService.updateForDirector` | `salaryRepository.updateForDirector` | `sp_Salary_Update_ForDirector`, `sp_Salary_UpsertCore`, `sp_AuditLog_Create`, salary tables | Director only |
| `GET /api/finance/payroll` | `finance.controller.getPayroll` | `financeService.getPayroll` | `financeRepository.findPayroll` -> salary repo | `sp_Salary_GetList_ForFinance` / `sp_Salary_GetList_ForDirector` | Finance Staff, Director |
| `GET /api/finance/payroll/:id` | `finance.controller.getPayrollById` | `financeService.getPayrollById` | `financeRepository.findPayrollByEmployeeId` -> salary repo | `sp_Salary_GetByEmployeeId_ForFinance` / `sp_Salary_GetByEmployeeId_ForDirector` | Finance Staff, Director |
| `GET /api/audit-logs` | `audit.controller.getLogs` | `auditService.getLogs` | `auditRepository.findAll` | `sp_AuditLog_List`, `Audit_Log` | HR Manager, Director |
| `GET /api-docs/openapi.json` | inline | N/A | N/A | None | Public |
| `GET /api-docs` | inline | N/A | N/A | None | Public |

---

## 6. Data model summary

### 6.1. Department

- Ý nghĩa nghiệp vụ: Phòng ban nhân sự
- Field chính: `DepartmentID`, `DepartmentName`, `ManagerID`
- Field nhạy cảm: Không đặc biệt nhạy cảm
- Encrypt/hash: Không
- Quan hệ:
  - 1-n với `Employee`
  - `ManagerID` FK tới `Employee.EmployeeID`
- API đọc/ghi:
  - Đọc: `GET /api/departments`
  - Ghi: `POST/PUT/DELETE /api/departments`

### 6.2. Position

- Ý nghĩa nghiệp vụ: Chức danh và hệ số mặc định
- Field chính: `PositionID`, `PositionName`, `PositionCoefficientDefault`, `Description`
- Field nhạy cảm: Không
- Encrypt/hash: Không
- Quan hệ: `Employee.PositionID`
- API đọc/ghi:
  - Không có endpoint trực tiếp
  - Được tham chiếu trong approval flow và HR Manager update employee

### 6.3. Employee

- Ý nghĩa nghiệp vụ: Hồ sơ nhân sự
- Field chính: `EmployeeID`, `FullName`, `Gender`, `DateOfBirth`, `PhoneNumber`, `DepartmentID`, `PositionID`, `EmploymentStatus`, `IsActive`, `CreatedAt`
- Field nhạy cảm:
  - `TaxIDEncrypted`
- Encrypt/hash:
  - `TaxIDEncrypted` lưu encrypted bằng symmetric key
- Quan hệ:
  - n-1 `Department`
  - n-1 `Position`
  - 1-1 `Account`
  - 1-1 `EmployeeSalaryConfig`
  - 1-1 `EmployeeSalaryResult`
- API đọc/ghi:
  - Đọc: `/api/employees`, `/api/employees/:id`
  - Ghi: approval create employee, `PUT /api/employees/:id`

### 6.4. Account

- Ý nghĩa nghiệp vụ: Tài khoản đăng nhập
- Field chính: `EmployeeID`, `Username`, `PasswordHash`, `PasswordSalt`, `Role`, `AccountStatus`, `IsActive`, `CreatedAt`
- Field nhạy cảm:
  - `PasswordHash`
  - `PasswordSalt`
- Encrypt/hash:
  - Password lưu hash bcrypt
  - Salt cũng được lưu riêng, dù bcrypt hash vốn đã chứa salt
- Quan hệ: FK tới `Employee`
- API đọc/ghi:
  - Đọc gián tiếp: login
  - Ghi: approval flow tạo account mới

### 6.5. EmployeeSalaryConfig

- Ý nghĩa nghiệp vụ: Input của salary formula
- Field chính:
  - `EmployeeID`
  - `BaseSalaryEncrypted`
  - `SalaryCoefficientEncrypted`
  - `PositionCoefficientEncrypted`
  - `AllowanceEncrypted`
  - `ApprovedBy`
  - `UpdatedAt`
  - `FormulaVersion`
- Field nhạy cảm:
  - Toàn bộ salary formula inputs
- Encrypt/hash:
  - Các salary inputs đều encrypted
- Quan hệ: 1-1 với `Employee`
- API đọc/ghi:
  - Đọc: Director salary endpoints, Director employee endpoints
  - Ghi: Director approve request, Director update salary

### 6.6. EmployeeSalaryResult

- Ý nghĩa nghiệp vụ: Kết quả `FinalSalary`
- Field chính: `EmployeeID`, `FinalSalaryEncrypted`, `CalculatedAt`
- Field nhạy cảm:
  - `FinalSalaryEncrypted`
- Encrypt/hash:
  - `FinalSalary` encrypted
- Quan hệ: 1-1 với `Employee`
- API đọc/ghi:
  - Đọc: Manager employee endpoints, Finance salary/employee endpoints, Director employee/salary endpoints
  - Ghi: `sp_Salary_UpsertCore`

### 6.7. HR_Request

- Ý nghĩa nghiệp vụ: Request nghiệp vụ, hiện tại dùng cho `CREATE_EMPLOYEE`
- Field chính: `RequestID`, `RequestType`, `Status`, `RequesterID`, `ApproverID`, `RequestPayload`, `CreatedAt`, `ApprovedAt`, `RejectionReason`
- Field nhạy cảm:
  - `RequestPayload` chứa password raw của candidate account
- Encrypt/hash:
  - Không thấy encryption/hash cho `RequestPayload`
- Quan hệ:
  - Logic nghiệp vụ liên kết tới `Employee` qua `RequesterID`/`ApproverID`, nhưng SQL schema không có FK
- API đọc/ghi:
  - Đọc: `/api/hr-requests*`, `/api/approvals/pending`
  - Ghi: `POST /api/hr-requests`, approval approve/reject

### 6.8. Audit_Log

- Ý nghĩa nghiệp vụ: Audit trail
- Field chính: `LogID`, `ActorID`, `ActorRole`, `ActionType`, `TableName`, `RecordID`, `OldValues`, `NewValues`, `Timestamp`
- Field nhạy cảm:
  - `OldValues`, `NewValues` có thể chứa data nhạy cảm
- Encrypt/hash:
  - Không thấy encryption
- Quan hệ: Không có FK rõ ràng
- API đọc/ghi:
  - Đọc: `GET /api/audit-logs`
  - Ghi: login/request/approval/department/employee/salary flows

---

## 7. Approval & salary flow analysis

### 7.1. Luồng chính

1. HR Staff gọi `POST /api/hr-requests`
2. Backend validate payload bằng `hrRequestCreateSchema`
3. `sp_HRRequest_Create` tạo record `PENDING`
4. Director gọi `GET /api/approvals/pending` để xem request chờ duyệt
5. Director gọi `POST /api/approvals/:requestId/approve`
6. Backend validate salary formula inputs
7. Backend đọc raw `RequestPayload` qua `sp_Approval_GetRequestForDirector`
8. Backend hash password bằng bcrypt
9. Backend gọi `sp_Approval_ApproveCreateEmployee`
10. Procedure parse JSON payload, validate department/position/username
11. Procedure tạo `Employee`
12. Procedure tạo `Account`
13. Procedure gọi `sp_Salary_UpsertCore`
14. `sp_Salary_UpsertCore` tính `FinalSalary = (BaseSalary × SalaryCoefficient × PositionCoefficient) + Allowance`
15. Procedure upsert `EmployeeSalaryConfig`
16. Procedure upsert `EmployeeSalaryResult`
17. Procedure update `HR_Request.Status = APPROVED`
18. App ghi `APPROVE_HR_REQUEST` vào `Audit_Log`

### 7.2. Flow reject

1. Director gọi `POST /api/approvals/:requestId/reject`
2. Validate `rejectionReason`
3. `sp_Approval_RejectRequest` update status `REJECTED`
4. App ghi `REJECT_HR_REQUEST` vào `Audit_Log`

### 7.3. Flow update salary sau khi employee đã tồn tại

1. Director gọi `PUT /api/salaries/:id`
2. Backend validate inputs
3. `sp_Salary_Update_ForDirector` lấy old values
4. Procedure gọi `sp_Salary_UpsertCore`
5. `sp_Salary_UpsertCore` tính lại final salary
6. Procedure update encrypted config/result rows
7. Procedure ghi `UPDATE_SALARY` vào `Audit_Log`
8. Procedure trả lại salary detail cho Director

### 7.4. Transaction / rollback

Observed in code:
- `approvalRepository.approveRequest` mở `sql.Transaction` ở app layer

Observed in SQL:
- `sp_Approval_ApproveCreateEmployee` có `BEGIN TRANSACTION`, `COMMIT`, `SET XACT_ABORT ON`
- `sp_Salary_Update_ForDirector` có `BEGIN TRANSACTION`, `COMMIT`, `SET XACT_ABORT ON`

Kết luận:
- Approval flow có transaction ở cả app layer và SQL layer
- Salary update flow có transaction trong SQL
- Rollback có ở app layer `catch -> transaction.rollback()` cho approval
- Rollback implicit ở SQL với `XACT_ABORT ON` khi statement fail

### 7.5. Validation đang có

Observed in code:
- Joi validation cho request body
- Role validation ở service

Observed in SQL:
- Check role qua `fn_RequesterContext`
- Check department tồn tại
- Check position tồn tại
- Check username unique
- Check request pending
- Check salary inputs positive / allowance >= 0

### 7.6. Security controls đang có

Observed in SQL:
- Encrypt tax ID
- Encrypt salary formula inputs và final salary
- `DENY` direct table access cho public
- Grant proc theo DB roles
- Mask password trên request read APIs

Observed in code:
- Password hash trước khi insert account
- JWT auth middleware
- Audit log nhiều hành động quan trọng

### 7.7. Rủi ro bảo mật / thiếu sót

- High: raw password nằm trong `HR_Request.RequestPayload` và không bị xóa sau approve/reject
- High: nhiều role ngoài Finance/Director vẫn thấy `TaxID`
- Medium: Manager thấy `Allowance` và `FinalSalary`
- Medium: DB role grants/denies không gắn trực tiếp với runtime app user identity
- Medium: refresh token không có revocation
- Medium: approval flow nested transaction ở app + SQL làm flow khó reason hơn

---

## 8. Known inconsistencies / gaps

| Severity | Location | Description | Recommendation |
| --- | --- | --- | --- |
| High | `sql/init.sql`, `sp_HRRequest_Create`, `sp_Approval_GetRequestForDirector`, `sp_Approval_ApproveCreateEmployee` | `HR_Request.RequestPayload` lưu raw password plaintext. Read API có mask nhưng dữ liệu gốc vẫn nằm trong DB kể cả sau approve/reject. | Không lưu password raw trong request; chuyển sang set password sau khi account được tạo, hoặc dùng one-time onboarding flow/token. |
| High | `sql/rbac_employee_procs.sql` employee/salary read procedures | `TaxID` được decrypt và trả cho Employee, Manager, HR Staff, HR Manager, Finance, Director. Đây là field nhạy cảm nhưng visibility hiện rất rộng. | Giảm scope `TaxID`, ưu tiên chỉ Director/Finance hoặc role thật sự cần. |
| Medium | `sql/rbac_employee_procs.sql` manager procedures | Manager thấy `Allowance` và `FinalSalary` trong employee endpoints. Điều này không khớp với kỳ vọng "Finance Staff chỉ xem final salary theo endpoint được cấp quyền". | Xem lại business rule; nếu Manager không nên thấy payroll, bỏ 2 field này khỏi proc Manager. |
| Medium | `src/modules/hr_request/request.service.js#getById` | `getById` gọi repository trước khi check role. Nếu role không hợp lệ, SQL ném lỗi trước và có thể surface thành `500`, không phải `403`. | Check role ở service trước khi chạm repository. |
| Medium | `src/middleware/role.js` | Có `restrictTo` nhưng không dùng ở route nào. Phần lớn role check nằm rải ở service. | Nếu muốn route contract rõ hơn, dùng `restrictTo` cho các route fixed-role như approvals/salaries/audit. |
| Medium | `src/modules/department/department.service.js#delete` + `sp_Department_Delete` | Delete department không trả `404` khi id không tồn tại; vẫn trả success và còn ghi audit `DELETE_DEPARTMENT`. | Check existence trước delete hoặc để proc throw lỗi cụ thể. |
| Medium | `src/modules/auth/auth.service.js#refresh` | Refresh token là stateless JWT, không lưu DB, không revoke, không rotate. | Thêm refresh token persistence, rotation, revoke/logout. |
| Medium | `src/modules/approval/approval.repository.js` + `sql/init.sql` | Approval flow có outer transaction ở Node và inner transaction trong proc SQL. Nested transaction này không cần thiết và làm flow khó debug. | Chọn một nơi ownership transaction, ưu tiên ở SQL nếu toàn bộ work nằm trong proc. |
| Medium | `src/modules/department/*` | Department write permission chỉ enforced ở service. Procedure không kiểm tra actor role bằng `RequesterEmployeeID`. | Nếu muốn defense-in-depth thật sự ở DB, bổ sung actor identity vào proc và validate trong SQL. |
| Medium | `src/middleware/error.js` | SQL `THROW` business errors thường rơi về `500`, làm API contract không ổn định cho frontend/tester. | Map lỗi SQL known business cases sang `400/403/404` nhất quán. |
| Low | `src/app.js`, docs endpoints | `/health`, `/api-docs/openapi.json`, `/api-docs` không theo wrapper response chuẩn. | Chấp nhận cho infra/docs hoặc document rõ như hiện tại. |
| Low | `src/modules/audit/audit.controller.js` + `sp_AuditLog_List` | Audit có `page`/`limit` nhưng API không trả `total`, `page`, `limit` trong `meta`. | Bổ sung meta pagination. |
| Low | `src/validations/schemas.js` | Nhiều field business quan trọng chỉ validate presence, chưa validate format mạnh như `phoneNumber`, `taxId`, `username`, tuổi lao động. | Bổ sung regex/range/business validation. |
| Low | `src/utils/salaryCalculator.js` | Có util `calculateFinalSalary` nhưng hiện không được dùng trong flow chính. | Hoặc bỏ util, hoặc dùng cho local pre-check consistent với SQL formula. |
| Low | `src/modules/docs/docs.routes.js` | Swagger UI load assets từ CDN `unpkg.com`; môi trường offline có thể không render docs UI. | Bundle asset nội bộ hoặc deploy static swagger assets. |

---

## 9. Suggested Swagger/OpenAPI structure

Đề xuất grouping, không thêm endpoint mới:

- `Infrastructure`
  - `GET /health`
  - `GET /api-docs/openapi.json`
  - `GET /api-docs`
- `Auth`
  - `POST /api/auth/login`
  - `POST /api/auth/refresh`
- `Departments`
  - `GET /api/departments`
  - `POST /api/departments`
  - `PUT /api/departments/{id}`
  - `DELETE /api/departments/{id}`
- `HR Requests`
  - `POST /api/hr-requests`
  - `GET /api/hr-requests`
  - `GET /api/hr-requests/{id}`
- `Approvals`
  - `GET /api/approvals/pending`
  - `POST /api/approvals/{requestId}/approve`
  - `POST /api/approvals/{requestId}/reject`
- `Employees`
  - `GET /api/employees`
  - `GET /api/employees/{id}`
  - `PUT /api/employees/{id}`
- `Salaries`
  - `GET /api/salaries`
  - `GET /api/salaries/{id}`
  - `PUT /api/salaries/{id}`
- `Finance`
  - `GET /api/finance/payroll`
  - `GET /api/finance/payroll/{id}`
- `Audit`
  - `GET /api/audit-logs`

OpenAPI nên mô tả rõ:
- OneOf response theo role cho employee/salary
- Security notes riêng cho salary/tax/audit
- Synthetic example phải gắn nhãn rõ
- Tag note cho alias `Finance` trỏ về `Salary`

---

## 10. Final coverage report

### 10.1. Coverage summary

- Tổng số endpoint tìm thấy: `24`
- Tổng số endpoint đã document: `24`
- Module đã cover:
  - Infrastructure
  - Auth
  - Departments
  - HR Requests
  - Approvals
  - Employees
  - Salaries
  - Finance
  - Audit
  - Docs
- File SQL đã đọc: `3/3`
  - `sql/init.sql`
  - `sql/seed.sql`
  - `sql/rbac_employee_procs.sql`
- Stored procedures đã đọc: `35`
- Functions đã đọc: `1`
- Views đã đọc: `0`
- Triggers đã đọc: `0`
- Database roles đã đọc: `6`

### 10.2. Runtime verification

Observed in test run:
- `npm test` đã pass `11/11 integration checks`
- Những hành vi đã được test runtime:
  - login cho toàn bộ seed users
  - employee list/detail RBAC
  - salary list/detail visibility
  - finance payroll alias
  - Director update salary
  - wrong-role blocking
  - validation reject invalid payload
  - HR request payload masking
  - OpenAPI endpoints
  - approvals pending

### 10.3. Những phần chưa verify được hoàn toàn

- `Not found / needs verification`: view/trigger vì không có file/object tương ứng
- Không có test runtime cho:
  - department create/update/delete happy path
  - approve/reject request end-to-end
  - audit query filter combinations
  - SQL error to HTTP status mapping cho từng proc branch
- Không có bằng chứng code cho:
  - versioning strategy chính thức
  - refresh token revocation/logout
  - field-level masking của `TaxID` theo policy chặt hơn

### 10.4. Kết luận ngắn

Source hiện tại đủ để viết Swagger/OpenAPI usable cho frontend và tester. Điểm mạnh nhất là employee/salary visibility được đẩy xuống stored procedure theo role. Điểm yếu lớn nhất là dữ liệu nhạy cảm vẫn lộ khá rộng (`TaxID`, manager thấy payroll-safe fields) và `HR_Request` đang lưu raw password trong DB.
