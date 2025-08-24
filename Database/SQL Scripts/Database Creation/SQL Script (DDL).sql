CREATE DATABASE db_online_learning_platform;
USE db_online_learning_platform;

-- =========================
-- System & Roles
-- =========================
CREATE TABLE Role (
    RoleID INT PRIMARY KEY IDENTITY(1001, 1001),
    RoleName VARCHAR(20) CHECK (RoleName IN ('Admin', 'Instructor', 'Student'))
);

CREATE TABLE SystemUser (
    UserID INT PRIMARY KEY IDENTITY(1111, 1),
    FirstName VARCHAR(25) NOT NULL,
    LastName VARCHAR(25) NOT NULL,
    BirthDate DATE NOT NULL,
    Nationality VARCHAR(25) NOT NULL,
    Mail VARCHAR(100) UNIQUE NOT NULL,
    [Password] VARCHAR(100) NOT NULL,
    Bio TEXT,
    BankAccount VARCHAR(20) UNIQUE NULL,
    ProfileName VARCHAR(50) UNIQUE,
    ProfilePhoto VARCHAR(255), -- URL
    DateOfCreation DATE DEFAULT GETDATE(),
    RoleID INT NOT NULL,
    [State] VARCHAR(10) CHECK ([State] IN ('AVAILABLE', 'REMOVED')) DEFAULT 'AVAILABLE',
    FOREIGN KEY (RoleID) REFERENCES Role(RoleID)
);

-- =========================
-- Course & Categories
-- =========================
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY IDENTITY(100, 100),
    CategoryType VARCHAR(50) CHECK (CategoryType IN (
        'Business', 'Design', 'Development', 'Finance & Accounting',
        'Health & Fitness', 'IT & Software', 'Lifestyle', 'Marketing',
        'Office Productivity', 'Personal Development',
        'Photography & Video', 'Teaching & Academics'
    ))
);

CREATE TABLE CourseCreation (
    CreationID INT PRIMARY KEY IDENTITY(1000, 1),
    CreationDate DATE DEFAULT GETDATE(),
    LastUpdateDate DATE,
    InstructorID INT NOT NULL,
    FOREIGN KEY (InstructorID) REFERENCES SystemUser(UserID)
);

CREATE TABLE Course (
    CourseID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    Description VARCHAR(MAX),
    Price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    CourseLevel VARCHAR(50) NOT NULL CHECK (CourseLevel IN ('Beginner', 'Intermediate', 'Professional', 'General')),
    CategoryID INT NOT NULL,
    CreationID INT NOT NULL,
    State VARCHAR(20) DEFAULT 'Pending' CHECK (State IN ('Pending', 'Approved', 'Rejected', 'Removed')),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    FOREIGN KEY (CreationID) REFERENCES CourseCreation(CreationID)
);

-- =========================
-- Enrollment & Certificate
-- =========================
CREATE TABLE Certificate (
    CertificateID INT PRIMARY KEY IDENTITY(1000, 1),
    GivenDate DATE NULL,
    CertificatePhoto VARCHAR(255) -- URL
);

CREATE TABLE Enrollment (
    EnrollmentID INT PRIMARY KEY IDENTITY(1000, 1),
    EnrollmentDate DATE DEFAULT GETDATE(),
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    CertificateID INT NULL,
    FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (CertificateID) REFERENCES Certificate(CertificateID)
);

-- =========================
-- Sections, Lessons & Content
-- =========================
CREATE TABLE Section (
    SectionID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    CourseID INT NOT NULL,
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

CREATE TABLE Quiz (
    QuizID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    SectionID INT UNIQUE,
    FOREIGN KEY (SectionID) REFERENCES Section(SectionID)
);

CREATE TABLE Lesson (
    LessonID INT PRIMARY KEY IDENTITY(1000, 1),
    Title VARCHAR(100) NOT NULL,
    SectionID INT NOT NULL,
    FOREIGN KEY (SectionID) REFERENCES Section(SectionID)
);

CREATE TABLE Content (
    ContentID INT PRIMARY KEY IDENTITY(1000, 1),
    ContentType VARCHAR(20) CHECK (ContentType IN ('TXT', 'PDF', 'Video')) NOT NULL,
    ContentData VARCHAR(255) -- URL
);

CREATE TABLE LessonContent (
    LessonID INT,
    ContentID INT,
    PRIMARY KEY (LessonID, ContentID),
    FOREIGN KEY (LessonID) REFERENCES Lesson(LessonID),
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID)
);

-- =========================
-- Quizzes & Questions
-- =========================
CREATE TABLE Question (
    QuesID INT PRIMARY KEY IDENTITY(1000, 1),
    QuesContent TEXT NOT NULL,
    ChooseA VARCHAR(255) NOT NULL,
    ChooseB VARCHAR(255) NOT NULL,
    ChooseC VARCHAR(255) NOT NULL,
    ChooseD VARCHAR(255) NOT NULL,
    CorrectChoice CHAR(1) CHECK (CorrectChoice IN ('A', 'B', 'C', 'D')) NOT NULL,
    QuizID INT NOT NULL,
    FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID)
);

CREATE TABLE StudentAnswer (
    StudentID INT,
    QuesID INT,
    [Choose] CHAR(1) CHECK ([Choose] IN ('A', 'B', 'C', 'D')) NOT NULL,
    PRIMARY KEY (StudentID, QuesID),
    FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (QuesID) REFERENCES Question(QuesID)
);

-- =========================
-- Student Progress
-- =========================
CREATE TABLE StudentLessonProgress (
    StudentID INT,
    LessonID INT,
    IsCompleted BIT DEFAULT 0,
    PRIMARY KEY (StudentID, LessonID),
    FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (LessonID) REFERENCES Lesson(LessonID)
);

CREATE TABLE StudentQuizProgress (
    StudentID INT,
    QuizID INT,
    IsPassed BIT DEFAULT 0,
    Score DECIMAL(5,2),
    PRIMARY KEY (StudentID, QuizID),
    FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID)
);

-- =========================
-- Reviews
-- =========================
CREATE TABLE Review (
    ReviewID INT PRIMARY KEY IDENTITY(6001, 1),
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (StudentID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- =========================
-- Notifications
-- =========================
CREATE TABLE NotificationType (
    TypeID INT PRIMARY KEY IDENTITY(1111, 1111),
    TypeName VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Notification (
    NotificationID INT PRIMARY KEY IDENTITY(5001, 1),
    UserID INT NOT NULL,
    TypeID INT NOT NULL,
    Message NVARCHAR(255) NOT NULL,
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    RelatedCourseID INT NULL,
    RelatedEnrollmentID INT NULL,
    FOREIGN KEY (UserID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (TypeID) REFERENCES NotificationType(TypeID),
    FOREIGN KEY (RelatedCourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (RelatedEnrollmentID) REFERENCES Enrollment(EnrollmentID)
);

-- =========================
-- Payments & Wallets
-- =========================

CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY IDENTITY(4001, 1),
    EnrollmentID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PlatformCut DECIMAL(10,2) NOT NULL,
    InstructorShare DECIMAL(10,2) NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod VARCHAR(50) CHECK (PaymentMethod IN ('CreditCard', 'PayPal', 'BankTransfer')),
    Status VARCHAR(20) CHECK (Status IN ('Pending','Completed','Failed')) DEFAULT 'Pending',
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID)
);

CREATE TABLE VirtualInstructorWallet (
    WalletID INT PRIMARY KEY IDENTITY(4001,1),
    UserID INT UNIQUE,
    Balance DECIMAL(12,2) DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES SystemUser(UserID)
);

CREATE TABLE VirtualPlatformWallet (
    WalletID INT PRIMARY KEY IDENTITY(5000,1),
    WalletName VARCHAR(100) DEFAULT 'MainPlatformWallet',
    Balance DECIMAL(12,2) DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE()
);

CREATE TABLE WalletTransaction (
    TransactionID INT PRIMARY KEY IDENTITY(4001,1),
    UserID INT NULL, -- null when platform transaction only
    Amount DECIMAL(12,2),
    TransactionType VARCHAR(10) CHECK (TransactionType IN ('CREDIT','DEBIT')),
    TransactionStatus VARCHAR(20) CHECK (TransactionStatus IN ('Completed','Reversed','Pending')) DEFAULT 'Completed',
    TransactionSource VARCHAR(50) NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    Description VARCHAR(255),
    RelatedPaymentID INT NULL,
    RelatedEnrollmentID INT NULL,
    FOREIGN KEY (UserID) REFERENCES SystemUser(UserID),
    FOREIGN KEY (RelatedPaymentID) REFERENCES Payment(PaymentID),
    FOREIGN KEY (RelatedEnrollmentID) REFERENCES Enrollment(EnrollmentID)
);