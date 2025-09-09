-- Insert Role names
INSERT INTO Role VALUES
('Admin'),
('Instructor'),
('Student')

-- Create Platform Account
INSERT INTO SystemUser (FirstName, Mail, [Password], RoleID) VALUES
('Platform', 'platform@gmail.com', 'platform1234', 1001)

-- Insert Categories
INSERT INTO Category VALUES
('Business'),
('Design'),
('Development'),
('Finance & Accounting'),
('Health & Fitness'),
('IT & Software'),
('Lifestyle'),
('Marketing'),
('Office Productivity'),
('Personal Development'),
('Photography & Video'),
('Teaching & Academics')

-- Insert Notification types
INSERT INTO NotificationType VALUES
('CourseSubmitted'),
('CourseApproved'),
('CourseRejected'),
('NewEnrollment'),
('CertificateGranted'),
('CourseUpdated');