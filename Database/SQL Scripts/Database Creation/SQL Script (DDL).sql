CREATE DATABASE db_online_learning_platform;

USE db_online_learning_platform;


CREATE TABLE SystemUser (
    UserID INT PRIMARY KEY IDENTITY(1111, 1),
    FirstName VARCHAR(25) NOT NULL,
    LastName VARCHAR(25) NOT NULL,
    BirthDate DATE NOT NULL,
    Nationality VARCHAR(25) NOT NULL,
    Mail VARCHAR(100) UNIQUE NOT NULL,
    [Password] VARCHAR(100) NOT NULL,
    Bio TEXT,
    BankAccount VARCHAR(20) UNIQUE NOT NULL,
    ProfileName VARCHAR(50) UNIQUE,
    ProfilePhoto VARCHAR(255), -- URL
    DateOfCreation DATE,
    RoleID INT NOT NULL,
    [State] VARCHAR(10) CHECK ([State] IN ('AVAILABLE', 'REMOVED')) DEFAULT 'AVAILABLE'
);

CREATE TABLE Role (
    RoleID INT PRIMARY KEY IDENTITY(1001, 1001),
    RoleName VARCHAR(20) CHECK (RoleName IN ('Admin', 'Instructor', 'Student'))
);

CREATE TABLE Enrollment (
    EnrollmentID INT PRIMARY KEY IDENTITY(1000, 1),
    EnrollmentDate DATE,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    CertificateID INT
);

CREATE TABLE Certificate (
    CertificateID INT PRIMARY KEY IDENTITY(1000, 1),
    GivenDate DATE,
    CertificatePhoto VARCHAR(255)  -- URL
);

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY IDENTITY(100, 100),
    CategoryType VARCHAR(50) CHECK (CategoryType IN (
        'Business', 'Design', 'Development', 'Finance & Accounting',
        'Health & Fitness', 'IT & Software', 'Lifestyle', 'Marketing',
        'Office Productivity', 'Personal Development',
        'Photography & Video', 'Teaching & Academics'
    ))
);

CREATE TABLE Course (
    CourseID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    Description VARCHAR(MAX),
    Price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    CourseLevel VARCHAR(50) CHECK (CourseLevel IN ('Beginner', 'Intermediate', 'Professional', 'General')) NOT NULL,
    CategoryID INT NOT NULL,
    CreationID INT NOT NULL
);

CREATE TABLE CourseCreation (
    CreationID INT PRIMARY KEY IDENTITY(1000, 1),
    CreationDate DATE,
    LastUpdateDate DATE,
    InstructorID INT NOT NULL
);

CREATE TABLE Section (
    SectionID INT PRIMARY KEY IDENTITY(1000, 1),
	Title VARCHAR(100) NOT NULL,
    CourseID INT NOT NULL,
    QuizID INT
);

CREATE TABLE Quiz (
    QuizID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL
);

CREATE TABLE Question (
    QuesID INT PRIMARY KEY IDENTITY(1000, 1),
    QuesContent TEXT NOT NULL,
    ChooseA VARCHAR(255) NOT NULL,
    ChooseB VARCHAR(255) NOT NULL,
    ChooseC VARCHAR(255) NOT NULL,
    ChooseD VARCHAR(255) NOT NULL,
    CorrectChoice CHAR(1) CHECK (CorrectChoice IN ('A', 'B', 'C', 'D')) NOT NULL,
    QuizID INT NOT NULL
);

CREATE TABLE StudentAnswer (
    StudentID INT,
    QuesID INT,
    [Choose] CHAR(1) CHECK ([Choose] IN ('A', 'B', 'C', 'D')) NOT NULL,
    PRIMARY KEY (StudentID, QuesID)
);

CREATE TABLE Lesson (
    LessonID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    SectionID INT
);

CREATE TABLE Content (
    ContentID INT PRIMARY KEY IDENTITY(1000, 1),
    ContentType VARCHAR(20) CHECK (ContentType IN ('TXT', 'PDF', 'Video')) NOT NULL,
    ContentData VARCHAR(255) -- URL
);

CREATE TABLE LessonContent (
    LessonID INT,
    ContentID INT,
    PRIMARY KEY (LessonID, ContentID)
);

-- Add foreign key constraints
ALTER TABLE SystemUser
ADD
FOREIGN KEY (RoleID) REFERENCES Role(RoleID);

ALTER TABLE Enrollment 
ADD 
FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
FOREIGN KEY (CertificateID) REFERENCES Certificate(CertificateID);

ALTER TABLE Course
ADD 
FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
FOREIGN KEY (CreationID) REFERENCES CourseCreation(CreationID);

ALTER TABLE CourseCreation
ADD
FOREIGN KEY (InstructorID) REFERENCES SystemUser(UserID);

ALTER TABLE Section
ADD
FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID);

ALTER TABLE Question
ADD 
FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID);

ALTER TABLE StudentAnswer
ADD
FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID), -- Corrected typo
FOREIGN KEY (QuesID) REFERENCES Question(QuesID);

ALTER TABLE Lesson
ADD 
FOREIGN KEY (SectionID) REFERENCES Section(SectionID);

ALTER TABLE LessonContent
ADD 
FOREIGN KEY (LessonID) REFERENCES Lesson(LessonID),
FOREIGN KEY (ContentID) REFERENCES Content(ContentID);