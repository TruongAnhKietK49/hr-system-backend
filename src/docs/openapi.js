export const openApiSpec = {
  openapi: '3.0.3',
  info: {
    title: 'HR Management Security System API',
    version: '1.0.0',
    description: 'OpenAPI spec for the HR backend aligned with SQL stored procedures and RBAC policy.'
  },
  servers: [
    {
      url: 'http://localhost:3000',
      description: 'Local development'
    }
  ],
  tags: [
    { name: 'Auth' },
    { name: 'Departments' },
    { name: 'HR Requests' },
    { name: 'Approvals' },
    { name: 'Employees' },
    { name: 'Salaries' },
    { name: 'Finance' },
    { name: 'Audit' }
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT'
      }
    },
    schemas: {
      ApiError: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Forbidden' }
        }
      },
      LoginRequest: {
        type: 'object',
        required: ['username', 'password'],
        properties: {
          username: { type: 'string', example: 'director01' },
          password: { type: 'string', example: '123456' }
        }
      },
      RefreshRequest: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string', example: 'jwt-refresh-token' }
        }
      },
      AuthTokens: {
        type: 'object',
        properties: {
          accessToken: { type: 'string', example: 'jwt-access-token' },
          refreshToken: { type: 'string', example: 'jwt-refresh-token' },
          user: {
            type: 'object',
            properties: {
              employeeId: { type: 'string', example: 'EM00001' },
              username: { type: 'string', example: 'director01' },
              fullName: { type: 'string', example: 'Director User' },
              role: { type: 'string', example: 'Director' },
              departmentId: { type: 'string', example: 'D004' }
            }
          }
        }
      },
      RefreshResponse: {
        type: 'object',
        properties: {
          accessToken: { type: 'string', example: 'jwt-access-token' }
        }
      },
      DepartmentWriteRequest: {
        type: 'object',
        properties: {
          departmentId: { type: 'string', example: 'D005' },
          departmentName: { type: 'string', example: 'Operations' },
          managerId: { type: 'string', nullable: true, example: 'EM00005' }
        }
      },
      Department: {
        type: 'object',
        properties: {
          DepartmentID: { type: 'string', example: 'D003' },
          DepartmentName: { type: 'string', example: 'Engineering' },
          ManagerID: { type: 'string', nullable: true, example: 'EM00005' }
        }
      },
      HrRequestCreate: {
        type: 'object',
        required: ['requestType', 'payload'],
        properties: {
          requestType: { type: 'string', example: 'CREATE_EMPLOYEE' },
          payload: {
            type: 'object',
            properties: {
              fullName: { type: 'string', example: 'New Employee' },
              gender: { type: 'string', example: 'Female' },
              dateOfBirth: { type: 'string', format: 'date', example: '1999-01-01' },
              phoneNumber: { type: 'string', example: '0901999888' },
              taxId: { type: 'string', example: '123456789' },
              departmentId: { type: 'string', example: 'D003' },
              positionId: { type: 'integer', example: 1 },
              username: { type: 'string', example: 'newemployee01' },
              password: { type: 'string', example: '123456' },
              role: { type: 'string', example: 'Employee' }
            }
          }
        }
      },
      HrRequestRecord: {
        type: 'object',
        properties: {
          RequestID: { type: 'integer', example: 1 },
          RequestType: { type: 'string', example: 'CREATE_EMPLOYEE' },
          Status: { type: 'string', example: 'PENDING' },
          RequesterID: { type: 'string', example: 'EM00003' },
          ApproverID: { type: 'string', nullable: true, example: 'EM00001' },
          RequestPayload: {
            type: 'string',
            example: '{"fullName":"Pending Employee User","username":"pendingemp01","role":"Employee"}'
          },
          CreatedAt: { type: 'string', format: 'date-time' },
          ApprovedAt: { type: 'string', format: 'date-time', nullable: true },
          RejectionReason: { type: 'string', nullable: true, example: null }
        }
      },
      ApprovalApproveRequest: {
        type: 'object',
        required: ['baseSalary', 'salaryCoefficient', 'positionCoefficient', 'allowance'],
        properties: {
          baseSalary: { type: 'number', example: 10000000 },
          salaryCoefficient: { type: 'number', example: 1.1 },
          positionCoefficient: { type: 'number', example: 1.0 },
          allowance: { type: 'number', example: 500000 },
          formulaVersion: { type: 'string', example: 'v1' }
        }
      },
      ApprovalRejectRequest: {
        type: 'object',
        required: ['rejectionReason'],
        properties: {
          rejectionReason: { type: 'string', example: 'Missing supporting documents' }
        }
      },
      EmployeeUpdateRequest: {
        type: 'object',
        description: 'Allowed fields depend on role. Employee/HR Staff can update only profile basics; HR Manager can update employment fields too.',
        properties: {
          fullName: { type: 'string', example: 'Updated Name' },
          gender: { type: 'string', example: 'Female', nullable: true },
          dateOfBirth: { type: 'string', format: 'date', example: '1998-11-25' },
          phoneNumber: { type: 'string', example: '0901222333' },
          departmentId: { type: 'string', example: 'D002' },
          positionId: { type: 'integer', example: 2 },
          employmentStatus: { type: 'string', example: 'ACTIVE' },
          isActive: { type: 'boolean', example: true }
        }
      },
      DirectorEmployeeRecord: {
        type: 'object',
        properties: {
          EmployeeID: { type: 'string', example: 'EM00006' },
          FullName: { type: 'string', example: 'Employee User' },
          Gender: { type: 'string', example: 'Female' },
          DateOfBirth: { type: 'string', format: 'date' },
          PhoneNumber: { type: 'string', example: '0901000006' },
          TaxID: { type: 'string', example: '666666666' },
          DepartmentID: { type: 'string', example: 'D003' },
          DepartmentName: { type: 'string', example: 'Engineering' },
          PositionID: { type: 'integer', example: 1 },
          EmploymentStatus: { type: 'string', example: 'ACTIVE' },
          IsActive: { type: 'boolean', example: true },
          CreatedAt: { type: 'string', format: 'date-time' },
          BaseSalary: { type: 'string', example: '10000000' },
          SalaryCoefficient: { type: 'string', example: '1.10' },
          PositionCoefficient: { type: 'string', example: '1.00' },
          Allowance: { type: 'string', example: '500000' },
          FinalSalary: { type: 'string', example: '11500000.00' }
        }
      },
      FinanceEmployeeRecord: {
        type: 'object',
        properties: {
          EmployeeID: { type: 'string', example: 'EM00005' },
          FullName: { type: 'string', nullable: true, example: null },
          Gender: { type: 'string', nullable: true, example: null },
          DateOfBirth: { type: 'string', format: 'date', nullable: true },
          PhoneNumber: { type: 'string', nullable: true, example: null },
          TaxID: { type: 'string', example: '555555555' },
          DepartmentID: { type: 'string', nullable: true, example: null },
          DepartmentName: { type: 'string', nullable: true, example: null },
          PositionID: { type: 'integer', nullable: true, example: null },
          EmploymentStatus: { type: 'string', nullable: true, example: null },
          IsActive: { type: 'boolean', nullable: true, example: null },
          CreatedAt: { type: 'string', format: 'date-time', nullable: true },
          Allowance: { type: 'string', example: '3000000' },
          FinalSalary: { type: 'string', example: '40800000' }
        }
      },
      SalaryUpdateRequest: {
        type: 'object',
        required: ['baseSalary', 'salaryCoefficient', 'positionCoefficient', 'allowance'],
        properties: {
          baseSalary: { type: 'number', example: 15000000 },
          salaryCoefficient: { type: 'number', example: 1.25 },
          positionCoefficient: { type: 'number', example: 1.1 },
          allowance: { type: 'number', example: 700000 },
          formulaVersion: { type: 'string', example: 'v2' }
        }
      },
      DirectorSalaryRecord: {
        type: 'object',
        properties: {
          EmployeeID: { type: 'string', example: 'EM00006' },
          FullName: { type: 'string', example: 'Employee User' },
          DepartmentID: { type: 'string', example: 'D003' },
          DepartmentName: { type: 'string', example: 'Engineering' },
          PositionID: { type: 'integer', example: 1 },
          TaxID: { type: 'string', example: '666666666' },
          BaseSalary: { type: 'string', example: '15000000' },
          SalaryCoefficient: { type: 'string', example: '1.25' },
          PositionCoefficient: { type: 'string', example: '1.10' },
          Allowance: { type: 'string', example: '700000' },
          FinalSalary: { type: 'string', example: '21325000.00' },
          FormulaVersion: { type: 'string', example: 'v2' },
          ApprovedBy: { type: 'string', example: 'EM00001' },
          SalaryUpdatedAt: { type: 'string', format: 'date-time' },
          SalaryCalculatedAt: { type: 'string', format: 'date-time' }
        }
      },
      FinanceSalaryRecord: {
        type: 'object',
        properties: {
          EmployeeID: { type: 'string', example: 'EM00005' },
          FullName: { type: 'string', nullable: true, example: null },
          DepartmentID: { type: 'string', nullable: true, example: null },
          DepartmentName: { type: 'string', nullable: true, example: null },
          TaxID: { type: 'string', example: '555555555' },
          Allowance: { type: 'string', example: '3000000' },
          FinalSalary: { type: 'string', example: '40800000' },
          FormulaVersion: { type: 'string', example: 'v1' },
          SalaryUpdatedAt: { type: 'string', format: 'date-time' },
          SalaryCalculatedAt: { type: 'string', format: 'date-time' }
        }
      },
      AuditRecord: {
        type: 'object',
        properties: {
          LogID: { type: 'integer', example: 1 },
          ActorID: { type: 'string', nullable: true, example: 'EM00001' },
          ActorRole: { type: 'string', nullable: true, example: 'Director' },
          ActionType: { type: 'string', example: 'UPDATE_SALARY' },
          TableName: { type: 'string', example: 'EmployeeSalaryConfig' },
          RecordID: { type: 'string', nullable: true, example: 'EM00006' },
          OldValues: { type: 'string', nullable: true },
          NewValues: { type: 'string', nullable: true },
          Timestamp: { type: 'string', format: 'date-time' }
        }
      }
    }
  },
  paths: {
    '/api/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Login with seeded or active account credentials',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LoginRequest' }
            }
          }
        },
        responses: {
          200: {
            description: 'Login successful',
            content: {
              'application/json': {
                examples: {
                  success: {
                    value: {
                      success: true,
                      message: 'Login successful',
                      data: {
                        accessToken: 'jwt-access-token',
                        refreshToken: 'jwt-refresh-token',
                        user: {
                          employeeId: 'EM00001',
                          username: 'director01',
                          fullName: 'Director User',
                          role: 'Director',
                          departmentId: 'D004'
                        }
                      }
                    }
                  }
                },
                schema: { $ref: '#/components/schemas/AuthTokens' }
              }
            }
          },
          401: {
            description: 'Invalid credentials',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/ApiError' } } }
          }
        }
      }
    },
    '/api/auth/refresh': {
      post: {
        tags: ['Auth'],
        summary: 'Refresh access token',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/RefreshRequest' } }
          }
        },
        responses: {
          200: {
            description: 'Token refreshed',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/RefreshResponse' } } }
          },
          401: {
            description: 'Invalid refresh token',
            content: { 'application/json': { schema: { $ref: '#/components/schemas/ApiError' } } }
          }
        }
      }
    },
    '/api/departments': {
      get: {
        tags: ['Departments'],
        summary: 'List departments',
        security: [{ bearerAuth: [] }],
        description: 'Authenticated users can read departments.',
        responses: {
          200: {
            description: 'Department list',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/Department' } }
              }
            }
          }
        }
      },
      post: {
        tags: ['Departments'],
        summary: 'Create department',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, HR Manager.',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/DepartmentWriteRequest' } }
          }
        },
        responses: {
          201: { description: 'Department created' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/departments/{id}': {
      put: {
        tags: ['Departments'],
        summary: 'Update department',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, HR Manager.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/DepartmentWriteRequest' } }
          }
        },
        responses: {
          200: { description: 'Department updated' },
          403: { description: 'Forbidden' },
          404: { description: 'Department not found' }
        }
      },
      delete: {
        tags: ['Departments'],
        summary: 'Delete department',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, HR Manager.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        responses: {
          200: { description: 'Department deleted' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/hr-requests': {
      get: {
        tags: ['HR Requests'],
        summary: 'List HR requests by SQL scope',
        security: [{ bearerAuth: [] }],
        description: 'Roles: HR Staff, HR Manager, Director. HR Staff sees only own requests. Payload returned from SQL is password-masked.',
        responses: {
          200: {
            description: 'HR request list',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/HrRequestRecord' } }
              }
            }
          }
        }
      },
      post: {
        tags: ['HR Requests'],
        summary: 'Create employee onboarding request',
        security: [{ bearerAuth: [] }],
        description: 'Role: HR Staff only.',
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/HrRequestCreate' } }
          }
        },
        responses: {
          201: { description: 'HR request created' },
          403: { description: 'Forbidden' },
          400: { description: 'Validation error' }
        }
      }
    },
    '/api/hr-requests/{id}': {
      get: {
        tags: ['HR Requests'],
        summary: 'Get HR request by scope',
        security: [{ bearerAuth: [] }],
        description: 'Roles: HR Staff, HR Manager, Director.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'integer' } }
        ],
        responses: {
          200: {
            description: 'HR request detail',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/HrRequestRecord' }
              }
            }
          },
          404: { description: 'HR request not found' }
        }
      }
    },
    '/api/approvals/pending': {
      get: {
        tags: ['Approvals'],
        summary: 'List pending approvals for Director',
        security: [{ bearerAuth: [] }],
        description: 'Role: Director only.',
        responses: {
          200: {
            description: 'Pending requests',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/HrRequestRecord' } }
              }
            }
          },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/approvals/{requestId}/approve': {
      post: {
        tags: ['Approvals'],
        summary: 'Approve create-employee request',
        security: [{ bearerAuth: [] }],
        description: 'Role: Director only. Backend hashes password, SQL creates employee/account/salary rows and calculates final salary.',
        parameters: [
          { name: 'requestId', in: 'path', required: true, schema: { type: 'integer' } }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/ApprovalApproveRequest' } }
          }
        },
        responses: {
          200: { description: 'Request approved' },
          403: { description: 'Forbidden' },
          404: { description: 'HR request not found' }
        }
      }
    },
    '/api/approvals/{requestId}/reject': {
      post: {
        tags: ['Approvals'],
        summary: 'Reject HR request',
        security: [{ bearerAuth: [] }],
        description: 'Role: Director only.',
        parameters: [
          { name: 'requestId', in: 'path', required: true, schema: { type: 'integer' } }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/ApprovalRejectRequest' } }
          }
        },
        responses: {
          200: { description: 'Request rejected' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/employees': {
      get: {
        tags: ['Employees'],
        summary: 'List employees with SQL-enforced RBAC',
        security: [{ bearerAuth: [] }],
        description: 'Role-specific behavior: Employee same department; Manager managed department; HR Staff excludes D001; HR Manager all employees; Finance masks non-finance profile but keeps TaxID/Allowance/FinalSalary; Director sees salary config/result.',
        responses: {
          200: {
            description: 'Employee list',
            content: {
              'application/json': {
                examples: {
                  director: {
                    value: {
                      success: true,
                      message: 'Employees fetched',
                      data: [
                        {
                          EmployeeID: 'EM00006',
                          FullName: 'Employee User',
                          BaseSalary: '10000000',
                          SalaryCoefficient: '1.10',
                          PositionCoefficient: '1.00',
                          Allowance: '500000',
                          FinalSalary: '11500000.00'
                        }
                      ]
                    }
                  },
                  finance: {
                    value: {
                      success: true,
                      message: 'Employees fetched',
                      data: [
                        {
                          EmployeeID: 'EM00005',
                          FullName: null,
                          TaxID: '555555555',
                          Allowance: '3000000',
                          FinalSalary: '40800000'
                        }
                      ]
                    }
                  }
                }
              }
            }
          },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/employees/{id}': {
      get: {
        tags: ['Employees'],
        summary: 'Get employee detail with SQL-enforced RBAC',
        security: [{ bearerAuth: [] }],
        description: 'Uses role-specific detail procedure, not generic filtering in controller/service.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        responses: {
          200: {
            description: 'Employee detail',
            content: {
              'application/json': {
                schema: {
                  oneOf: [
                    { $ref: '#/components/schemas/DirectorEmployeeRecord' },
                    { $ref: '#/components/schemas/FinanceEmployeeRecord' }
                  ]
                }
              }
            }
          },
          404: { description: 'Employee not found or out of scope' }
        }
      },
      put: {
        tags: ['Employees'],
        summary: 'Update employee profile by allowed role and field scope',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Employee, HR Staff, HR Manager. Salary fields are not accepted here.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/EmployeeUpdateRequest' } }
          }
        },
        responses: {
          200: { description: 'Employee updated' },
          400: { description: 'Validation error or no allowed fields to update' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/salaries': {
      get: {
        tags: ['Salaries'],
        summary: 'List salaries by role',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, Finance Staff. Director sees base salary and coefficients. Finance sees allowance/final salary only, with profile masking outside Finance.',
        responses: {
          200: {
            description: 'Salary list',
            content: {
              'application/json': {
                schema: {
                  oneOf: [
                    { type: 'array', items: { $ref: '#/components/schemas/DirectorSalaryRecord' } },
                    { type: 'array', items: { $ref: '#/components/schemas/FinanceSalaryRecord' } }
                  ]
                }
              }
            }
          },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/salaries/{id}': {
      get: {
        tags: ['Salaries'],
        summary: 'Get salary detail by employee id',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, Finance Staff.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        responses: {
          200: {
            description: 'Salary detail',
            content: {
              'application/json': {
                schema: {
                  oneOf: [
                    { $ref: '#/components/schemas/DirectorSalaryRecord' },
                    { $ref: '#/components/schemas/FinanceSalaryRecord' }
                  ]
                }
              }
            }
          },
          404: { description: 'Salary not found' }
        }
      },
      put: {
        tags: ['Salaries'],
        summary: 'Update salary by Director',
        security: [{ bearerAuth: [] }],
        description: 'Role: Director only. SQL computes FinalSalary and upserts both salary config/result rows in a transaction.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/SalaryUpdateRequest' } }
          }
        },
        responses: {
          200: {
            description: 'Salary updated',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/DirectorSalaryRecord' }
              }
            }
          },
          400: { description: 'Validation error' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/finance/payroll': {
      get: {
        tags: ['Finance'],
        summary: 'Legacy payroll alias for salary list',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, Finance Staff. Behavior matches GET /api/salaries.',
        responses: {
          200: { description: 'Payroll list' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/finance/payroll/{id}': {
      get: {
        tags: ['Finance'],
        summary: 'Legacy payroll alias for salary detail',
        security: [{ bearerAuth: [] }],
        description: 'Roles: Director, Finance Staff. Behavior matches GET /api/salaries/{id}.',
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
        ],
        responses: {
          200: { description: 'Payroll detail' },
          403: { description: 'Forbidden' }
        }
      }
    },
    '/api/audit-logs': {
      get: {
        tags: ['Audit'],
        summary: 'List audit logs',
        security: [{ bearerAuth: [] }],
        description: 'Roles: HR Manager, Director.',
        parameters: [
          { name: 'actorId', in: 'query', schema: { type: 'string' } },
          { name: 'actorRole', in: 'query', schema: { type: 'string' } },
          { name: 'actionType', in: 'query', schema: { type: 'string' } },
          { name: 'tableName', in: 'query', schema: { type: 'string' } },
          { name: 'startDate', in: 'query', schema: { type: 'string', format: 'date-time' } },
          { name: 'endDate', in: 'query', schema: { type: 'string', format: 'date-time' } },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } }
        ],
        responses: {
          200: {
            description: 'Audit logs',
            content: {
              'application/json': {
                schema: { type: 'array', items: { $ref: '#/components/schemas/AuditRecord' } }
              }
            }
          },
          403: { description: 'Forbidden' }
        }
      }
    }
  }
};
