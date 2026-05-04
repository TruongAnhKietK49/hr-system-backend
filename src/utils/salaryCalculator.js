export const calculateFinalSalary = ({ baseSalary, salaryCoefficient, positionCoefficient, allowance }) => {
  return (Number(baseSalary) * Number(salaryCoefficient) * Number(positionCoefficient)) + Number(allowance);
};
