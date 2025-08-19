-- sp_GetTotalUsers
CREATE PROCEDURE sp_GetTotalUsers
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users
	SELECT COUNT(UserID) TotalUsers
	FROM SystemUser

    SET @ResultMessage = 'Done';
END;
-------------------------------------------------------------------------------------
-- sp_GetTotalUsersByRole
CREATE PROCEDURE sp_GetTotalUsersByRole
    @RoleID INT,
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of users by role
    SELECT COUNT(UserID) AS TotalUsers
    FROM SystemUser
    WHERE RoleID = @RoleID;

    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------------
-- sp_GetTotalCourses
CREATE PROCEDURE sp_GetTotalCourses
    @ResultMessage VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Calc the total number of courses
	SELECT COUNT(CourseID) TotalCourses
	FROM Course

    SET @ResultMessage = 'Done';
END;
---------------------------------------------------------------------------------------
--
