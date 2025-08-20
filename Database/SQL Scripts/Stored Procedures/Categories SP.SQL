-- sp_GetAllCategories
CREATE PROCEDURE sp_GetAllCategories
     @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
   SELECT CategoryType
   FROM Category

   SET @ResultMessage = 'Done'
END;