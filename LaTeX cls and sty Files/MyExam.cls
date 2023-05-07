
%% Package Declarations and Identification
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{MyExam}[2018/07/28; A class file for writing exams for calculus and lower courses.]
\LoadClass[12pt]{article}


%%%% Declare blank commands to be renewed below. This is to allow for having to overwrite whatever other packages are trying to use these commands for. Noteworthy that it will overwrite the commands unless the package is loaded later or defined in some weird way, so this may cause unexpected behavior depending on user configuration.

\providecommand{\Coordinator}{}%    Used for Front Cover Design
\providecommand{\Institution}{University of Florida}%    Used for Front Cover Design
\providecommand{\Course}{}%         Used for Front Cover Design
\providecommand{\Term}{}%           Used for Front Cover Design
\providecommand{\ExamForm}{}%       Used to contain the Exam's form letter. Supports A through E.
\providecommand{\ExamNum}{}%        Used to contain the Exam number, eg Exam 1
\providecommand{\Term}[1]{}% This takes a word (The term name; Fall, Spring, Summer A, Summer B, or Summer C) and saves it as \Term

%%%%%%%%%%%%%%%%%%%%%%%% End of Declaration and Identification


%% Required Packages
\RequirePackage[margin=2.5cm]{geometry}% Set generic Margins to 1.5cm
\RequirePackage{fancyhdr}% Used to make header/footers
\RequirePackage[hidelinks]{hyperref}%
\RequirePackage{tikz, pgfplots}
\RequirePackage{forloop}
\RequirePackage{changepage}
\RequirePackage{morewrites}


%%%%%%%%%%%%%%%%%%%%%%%% End of Required Packages



%% Necessary Counters

\newcounter{seedval}% A stable seed value that is determined by \GenTermSeed and used to randomize locations.
\newcounter{termNum}% Term number set by the current Term name that is used to calculate seedval.
\newcounter{formNum}% A number set by form code letter that is used to calculate seedval.
\newcounter{choiceNum}% This will track the choice number in a given MCChoice environment.
\newcounter{choiceEnvNum}% This lets the \choice generated commands be uniquely identified to the correct MCChoice environment.
    \setcounter{choiceEnvNum}{0}% Start at 0 as we step the counter before assigning things.
\newcounter{questionNum}% Tracks what number a question is within a given MCQ environment.
\newcounter{questionEnvNum}% Keep track of question environment blocks to assign unique identifiers
    \setcounter{questionEnvNum}{0}% Start at 0 as we step the counter before assigning things.
\newcounter{blockNum}% Which shuffle Block are we in
    \setcounter{blockNum}{0}% Start at 0 as we step the counter before assigning things.
\newcounter{questionNumInBlock}% Keeps track of which question within the given block we're in, to form a real question command later.

% Iteration counters
\newcounter{Iteration@printChoices}
\newcounter{Iteration@questionsInBlock}
\newcounter{Iteration@printQuestions}

%% End Counters

%% New "if" commands
\newif\ifVerbose% For error Checking
\Verbosefalse

\newif\ifquestionInBlock
\questionInBlockfalse

\newif\ifInner@Shuffle% If we want our vector to be shuffled
\Inner@Shufflefalse

\newif\ifInner@OrderForward% If we want non-shuffled and original order (smallest value to biggest value).
\Inner@OrderForwardfalse

\newif\ifInner@OrderReverse% If we want non-shuffled but reverse order (biggest value to smallest value).
\Inner@OrderReversefalse

\newif\ifshuffleChoices%    Toggle to shuffle choice locations.
\shuffleChoicesfalse

\newif\ifshuffleQuestions%  Toggle to shuffle Question locations.
\shuffleQuestionsfalse

\newif\ifinsideShuffleBlock% Used to keep track of if we are in a shuffle block or not, so we know if we need to be stepping counters or not.
\insideShuffleBlockfalse

\newif\ifgenAnsKey% Tracks if we want 
\genAnsKeyfalse

\newif\ifcorrectAns% This will track if a choice is correct.
\correctAnsfalse

%% End "if" commands

%% Package Options

%\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\DeclareOption{shuffleChoices}{% This class option will make all choices shuffled.
    \shuffleChoicestrue
    }% End shuffleChoices option


\DeclareOption{shuffleQuestions}{% This class option will shuffle question locations.
    \shuffleQuestionstrue
    }% End shuffleChoices option


\DeclareOption{shuffleAll}{% This class option will shuffle question and choice locations.
    \shuffleQuestionstrue
    \shuffleChoicestrue
    }% End shuffleChoices option

\DeclareOption{Key}{% This class option will shuffle question and choice locations.
    \genAnsKeytrue
    }% End shuffleChoices option



%%%%%%%%%%%%%%%%%%%%%%%% End of Package Options


%%% Support commands %%%
\providecommand\compareStrings[2]{% Used to compare two strings to see if they are the same - up to case sensitivity.
\edef\tempA{\lowercase{\noexpand\ifnum0=\noexpand\pdfstrcmp
    {\noexpand\zap@space#1 \noexpand\@empty}%
    {\noexpand\zap@space#2 \noexpand\@empty}%
}\relax}%
\tempA
    \expandafter\@firstoftwo
  \else
    \expandafter\@secondoftwo
  \fi}

\newcommand{\MakeCounter}[1]{%% Code located in "Utilitymacros.dtx"
  \@ifundefined{c@#1}% Check to see if counter exists
       {     % If not, create it and set it to 0.
\newcounter{#1}
\setcounter{#1}{0}
}
{%If so, reset to 0.
\setcounter{#1}{0}
}
}



%% Commands to help write out an answer key.
\newcommand{\file@Write}[1]{
\immediate\write\ExamKey{#1}
}

\newcommand{\file@Initialize}{
\expandafter\newwrite\expandafter\ExamKey\expandafter\immediate\expandafter\openout\expandafter\ExamKey=\expandafter\jobname-Key--Form-\ExamForm\relax
}

%%%%% End support commands %%%%



\def\TermNum{% This sets a number based on the (hopefully already set) term value for setting a seed. If Term is undefined or empty, it should return 1.
\compareStrings{\Term}{fall}{% The "Fall" term will have prime factor of 2
    \setcounter{termNum}{2}
    }
    {
    \compareStrings{\Term}{spring}{% The "Spring" term will have prime factor of 3
        \setcounter{termNum}{3}
        }
        {
        \compareStrings{\Term}{summera}{% The "Summer A" term will have prime factor of 5}
            \setcounter{termNum}{5}
            }
            {
            \compareStrings{\Term}{summerb}{% The "Summer B" term will have prime factor of 7
                \setcounter{termNum}{7}
                }
                {
                \compareStrings{\Term}{summerc}{% The "Summer C" term will have prime factor of 9
                    \setcounter{termNum}{9}
                    }% End "Summer C" condition
                    {% Otherwise, I have no idea wtf term you think you're doing, so we return 1
                    \setcounter{termNum}{1}
                    }% End "Else" condition
                }% End "Summer B" condition
            }% End "Summer A" condition
        }% End "Spring" condition
    }% End "Fall" condition
}%




\def\FormNum{% This sets a number based on the (hopefully already set) term value for setting a seed. If Term is undefined or empty, it should return 1.
\compareStrings{\ExamForm}{A}{% Form A will have prime factor of 11
    \setcounter{formNum}{11}
    }
    {
    \compareStrings{\ExamForm}{B}{% Form B will have prime factor of 13
        \setcounter{formNum}{13}
        }
        {
        \compareStrings{\ExamForm}{C}{% The Form C will have prime factor of 17
            \setcounter{formNum}{17}
            }
            {
            \compareStrings{\ExamForm}{D}{% The Form D will have prime factor of 19
                \setcounter{formNum}{19}
                }
                {
                \compareStrings{\ExamForm}{E}{% The Form E will have prime factor of 23
                    \setcounter{formNum}{23}
                    }% End "Summer C" condition
                    {% Otherwise, I have no idea wtf term you think you're doing, so we return 1
                    \setcounter{formNum}{1}
                    }% End Form E condition
                }% End Form D condition
            }% End Form C condition
        }% End Form B condition
    }% End Form A condition
}%




\providecommand{\GenTermSeed}{% This is used to generate a seed based on the current term, year, and Form Letter 
%                               to generate stable/recreatable randomized numbers that will none-the-less change 
%                               every semester.
\FormNum
\TermNum

\expandafter\edef\expandafter\TempCount\expandafter{\numexpr \thetermNum * \year * \theformNum \relax}

\setcounter{seedval}{\TempCount}

\pgfmathsetseed{\theseedval}
}%





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%		  Randomize Commands		%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  Random Permutation Command  %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\MakeCounter{RndQuant}%		        Tracks the number of desired counters
\MakeCounter{Temp@Hold}%		    Temp counter to hold the command value because tex is weird.
\MakeCounter{Temp@RandMe}%	        Temp counter like previous.

\newcommand*\ifcounter[2]{%         Function checks if a counter named #1 exists. If not it creates it. After existance is confirmed (or implemented), set the counter to #2.
  \ifcsname c@#1\endcsname
  \else
    \MakeCounter{#1}
  \fi
\setcounter{#1}{#2}
}

\newcommand{\RandMe}[3]{% #1 is the max number for range, #2 is the name of the counter to hold the list, and #3 is how many from that list to generate. Thus \RandMe{100}{TEMP}{5} will generate 5 counters, named \TEMPI, \TEMPII, \TEMPIII, \TEMPIV, \TEMPV. Each of which will have a (unique) number between 1 and 100.

    %Assign a maximum on how many numbers to pick. Set default to the max list size, and save in counter "RndQuant"
    \ifthenelse{\isempty{#3}}
        {
        \setcounter{RndQuant}{#1+1}
        }
        {
        \setcounter{RndQuant}{#3+1}
        }

    %Generate a starting list of numbers 1 to maximum number given
    \forloop{Iteration1}{1}{\arabic{Iteration1} < \arabic{RndQuant}}{
        \ifcounter{#2\Roman{Iteration1}}{\arabic{Iteration1}}
        }% End Forloop
    
    
    %Permute using Knuth method
    \forloop{Iteration1}{1}{\arabic{Iteration1} < \arabic{RndQuant}}{
        \@genrand{TempRandMe}{\arabic{Iteration1}}{#1}
    
        \ifcounter{Temp@RandMe}{\TempRandMe}
        \ifcounter{Temp@Hold}{\arabic{#2\Roman{Temp@RandMe}}}
        
        \ifcounter{#2\Roman{Temp@RandMe}}{\arabic{#2\Roman{Iteration1}}}
        \ifcounter{#2\Roman{Iteration1}}{\arabic{Temp@Hold}}
    }
}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  Random Permutation Command  %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\newcommand{\@genrand}[3]{%\@genrand{NAME}{MIN}{MAX} generates a random number before MIN and MAX and stores it in the command \NAME. 
    \expandafter\pgfmathrandominteger\csname #1\endcsname{#2}{#3}
    \setcounter{#1}{\csname #1\endcsname}
}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%  		Make Vector is used to generate most random lists		%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\MakeCounter{Temp@1}
\MakeCounter{Temp@2}
\MakeCounter{Temp@3}
\MakeCounter{Iteration@1}
\MakeCounter{Iteration@2}
\MakeCounter{Iteration@3}
\MakeCounter{Iteration@4}
\MakeCounter{Placement@1}
\setcounter{Placement@1}{1}



%%%%%%%% Internal Keys
%% These are to use for internal flags only.
\newcommand{\inner@SetKeys}[1]{
\setkeys{key@Inner}{InnerShuffle={}, Order@Direction={},#1}
}


\define@key{key@Inner}{InnerShuffle}{% This flag is for shuffling questions.
\ifthenelse{\equal{#1}{true}}
	{
	\Inner@Shuffletrue
	}
	{
	\Inner@Shufflefalse
	}
}

\define@key{key@Inner}{Order@Direction}{% This flag gives the order in which vectors are saved.
\ifthenelse{\equal{#1}{forward}}
	{
	\Inner@OrderForwardtrue
	}
	{
	\Inner@OrderForwardfalse
	}
\ifthenelse{\equal{#1}{reverse}}
	{
	\Inner@OrderReversetrue
	}
	{
	\Inner@OrderReversefalse
	}
}



\newcommand{\make@Vector}[5][InnerShuffle=false, Order@Direction=forward]{% This is to make either an ordered or a shuffled list of values
	% #1 is optional and is for internal flags. 
	% #2 is the name of the output counters
	% #3 is the minimum counter value
	% #4 is the maximum counter value
	% #5 is the number of desired counters.
	% Counters will be saved as #2\Roman{#}
	
	\inner@SetKeys{#1}% Set any given keys
	% Possible flags:
		% InnerShuffle flag "true" will shuffle, "false" won't
		% Order@Direction; "forward" will list questions in increasing order. "reverse" will list the questions in 					decreasing order
		% 
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%  		First we will choose and order the initial values		%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	\setcounter{Temp@1}{#4}
	\addtocounter{Temp@1}{-#3}
	\ifnum #5 = \value{Temp@1}% The special case where we want all the values. Randomizing into a full list just to order it is silly so we deal with this case separately.
		\forloop{Iteration@1}{1}{\arabic{Iteration@1} < \arabic{Temp@1}}
			{% Start of forloop
			\MakeCounter{Ordered@\Roman{Iteration@1}}	% Check to see if counter exists
			\MakeCounter{C@Shuffle\Roman{Iteration@1}}
			\setcounter{Ordered@\Roman{Iteration@1}}{\arabic{Iteration@1}}
			\setcounter{C@Shuffle\Roman{Iteration@1}}{\arabic{Iteration@1}}
			}
	\else% If we don't want a full list, then we need to choose some.
		\setcounter{Temp@1}{#5}% Track how many numbers we want.
		\stepcounter{Temp@1}% Step for the < sign
		\forloop{Iteration@1}{1}{\arabic{Iteration@1} < \arabic{Temp@1}}
			{% Start of forloop
	
			\MakeCounter{Ordered@\Roman{Iteration@1}}	% Check to see if counter exists
			\MakeCounter{CTemp\Roman{Iteration@1}}	% Check to see if counter exists
			\MakeCounter{C@Shuffle\Roman{Iteration@1}}
		
			\@genrand{Temp@2}{#3}{#4}
			\ifVerbose{Your first choice for the question number is \arabic{Temp@2}}\\ \fi
			\forloop{Iteration@2}{1}{\arabic{Iteration@2} < \arabic{Iteration@1}}
				{% Start of inner forloop. This loop checks for uniqueness of counter value.
				\ifnum\value{Temp@2}=\value{CTemp\Roman{Iteration@2}}% Check to see if the counter matches any previous counter
				\@genrand{Temp@2}{#3}{#4}% If so, fix it.
				\setcounter{Iteration@2}{0}% Reset the check counter so we can check if the new number is used.
				\ifVerbose Your revised choice for the number is \arabic{Temp@2} \\ \fi
				\fi
	%			\arabic{Iteration@2}, \arabic{CTemp\Roman{Iteration@2}}\\
				}% 
			
			\setcounter{CTemp\Roman{Iteration@1}}{\arabic{Temp@2}}% Save (unsorted) unique value in a temp list of variables.
			\setcounter{C@Shuffle\Roman{Iteration@1}}{\arabic{Temp@2}}% Save (unsorted) unique value in a temp list of variables. This one is to be used in the case we want shuffled values at the end.
		
			\ifVerbose (Unordered) We want questions number \arabic{Temp@2} \fi
		
			}
		% Now we want to sort the list	
	
		\forloop{Iteration@3}{1}{\arabic{Iteration@3}<\arabic{Temp@1}}
			{% For each variable
				\setcounter{Placement@1}{1}% Default the placeholder counter to some gigantic number so I can proceed to find the smallest possible number.
			
				\forloop{Iteration@4}{1}{\arabic{Iteration@4}<\arabic{Temp@1}}
					{
					\ifnum\value{CTemp\Roman{Iteration@4}}<\value{CTemp\Roman{Placement@1}}
						\setcounter{Placement@1}{\arabic{Iteration@4}}% Keep track of which counter was the largest so far
					\fi
					}
	
				\setcounter{Ordered@\Roman{Iteration@3}}{\arabic{CTemp\Roman{Placement@1}}}% Set the final counter.
				\setcounter{CTemp\Roman{Placement@1}}{999999}% Now remove that place as a viable option for next run.
				\ifVerbose (Ordered) We want question number \arabic{Ordered@\Roman{Iteration@3}} \fi
			}
	\fi	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
%%%%%%%%%%%		Finished Choosing and ordering initial values		%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%   		Now reorder and assign final names				%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	
	\ifInner@OrderReverse
		\setcounter{Temp@3}{#5}
		\forloop{Iteration@1}{1}{\arabic{Iteration@1} < \arabic{Temp@1}}
			{
			\MakeCounter{#2\Roman{Iteration@1}}% Make the counter if it doesn't exist.
			\setcounter{#2\Roman{Iteration@1}}{\arabic{Ordered@\Roman{Temp@3}}}% Set the final counter version to the current "last" unused value.
			\addtocounter{Temp@3}{-1}% Decrement the counter for next assignment
			}
	\else% If we aren't doing it in reverse, assume we want forward order. This is default.
		\forloop{Iteration@1}{1}{\arabic{Iteration@1} < \arabic{Temp@1}}
			{
			\MakeCounter{#2\Roman{Iteration@1}}% Make the counter if it doesn't exist.
			\setcounter{#2\Roman{Iteration@1}}{\arabic{Ordered@\Roman{Iteration@1}}}% Set the final counter version to the next value.
			}
	
	\fi% End of forward/reverse order version

	\ifInner@Shuffle
		\forloop{Iteration@1}{1}{\arabic{Iteration@1} < \arabic{Temp@1}}
			{
			\MakeCounter{#2\Roman{Iteration@1}}% Make the counter if it doesn't exist.
			\setcounter{#2\Roman{Iteration@1}}{\arabic{C@Shuffle\Roman{Iteration@1}}}% Set the counter to the next value.
			}

	\fi% End of Shuffle order version
	
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%       Question Environments and Commands      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%% The multiple choice qustion environment
\newenvironment{MCQuestions}{% Start environment code
        \setcounter{questionNum}{0}% New MCQ environment means a new set of questions, so reset current question count to 0.
        \refstepcounter{questionEnvNum}% Unique pretag to identify which questions are in this MCQ block.
        
    }% End start environment code
    {% End environment code
        \begin{enumerate}
        \printQuestions
        \end{enumerate}
    }% End of end environment code.
    

\providecommand{\printQuestions}{% This is a command that will print questions that were defined in the current question environment.
    %First, we make the call vector based on if we are shuffling these or not.
        \ifshuffleQuestions% If we are shuffling, then shuffle up the call
            \make@Vector[InnerShuffle=true]{questionLoc}{1}{\arabic{questionNum}}{\arabic{questionNum}}
        \else% Otherwise, display them in original first to last order.
            \make@Vector[InnerShuffle=false, Order@Direction=forward]{questionLoc}{1}{\arabic{questionNum}}{\arabic{questionNum}}
        \fi	
        
    	% Now print the results:
    	
        \refstepcounter{questionNum}% Step counter for the < symbol in foreloop.
        
        \forloop{Iteration@printQuestions}{1}{\arabic{Iteration@printQuestions}<\arabic{questionNum}}{% Begin forloop
            \csname \Roman{questionEnvNum}question\expandafter\roman{questionLoc\Roman{Iteration@printQuestions}}\endcsname% Print choice
            }% End forloop
    }% End \printQuestions code.

\newcommand{\question}[1]{% Question command should contain a question to be formatted.
        \ifquestionInBlock
            \expandafter\stepcounter{questionNumInBlock\Roman{blockNum}}
            \expandafter\gdef\csname \Roman{blockNum}questionInBlock\expandafter\roman{questionNumInBlock\Roman{blockNum}}\endcsname{\noexpand{\begin{minipage}{\linewidth}\item #1\end{minipage}\\\vfill}}
        \else
            \stepcounter{questionNum}% A new question means we need to step current question count (before definition since counter starts at 0)
            \expandafter\def\csname \Roman{questionEnvNum}question\roman{questionNum}\endcsname{\noexpand{\begin{minipage}{\linewidth}\item #1\end{minipage}\\\vfill}}
        \fi
    }% End \question code
    
    

% Shuffle Block Code
\newenvironment{shuffleBlock}{% Begin of begin-environment code.
        \stepcounter{blockNum}
        \questionInBlocktrue
        \expandafter\newcounter{questionNumInBlock\Roman{blockNum}}
        \expandafter\setcounter{questionNumInBlock\Roman{blockNum}}{0}
    }% End of begin-environment code.
    {% Begin of end-environment code.
        \makeQuestionBlock% Now that we have all the previous questions, we can make one "question" that has all of the env's questions, in order.
        \questionInBlockfalse
    }% End of end-environment code.
    
\providecommand{\makeQuestionBlock}{% This will take the contents of a shuffleBlock and make a single "question" out of it.
    \expandafter\stepcounter{questionNumInBlock\Roman{blockNum}}% Stepped for the < in the forloop below.
    \stepcounter{questionNum}% This is stepped so we can make one master question that represents the block.
    \expandafter\gdef\csname \Roman{questionEnvNum}question\roman{questionNum}\endcsname{% Start master Q def:
%        \noexpand{
            \forloop{Iteration@questionsInBlock}{1}{\arabic{Iteration@questionsInBlock}<\expandafter\arabic{questionNumInBlock\Roman{blockNum}}}{
            \csname\Roman{blockNum}questionInBlock\expandafter\roman{Iteration@questionsInBlock}\endcsname
            }% End of forloop
%            }% End of noexpand
        }% End of master Q content
    }% End \makeQuestionBlock code.    
    

\newenvironment{choices}{% Start environment code for multiple choice Choices environment
        \setcounter{choiceNum}{0}% New MCChoices environment means a new set of choices, so reset current choice to 0.
        \refstepcounter{choiceEnvNum}
    }% End of start-environment code.
    {% Start of end-environment code.
        \printChoices
    }% End of end-environment code.
   



    
        
\newcommand{\choice}[2][incorrect]{% Choice command holds a multiple choice option by generating a new command with unique name that will be used to write the outputs at the end of the MCChoices environment.
        \refstepcounter{choiceNum}% A new choice means we need to step current choice (before definition since counters starts at 0)
        \compareStrings{#1}{correct}
            {% If it is marked as correct we will record the letter assignment.
            \expandafter\def\csname \Roman{choiceEnvNum}choice\roman{choiceNum}\endcsname{#2 \ifgenAnsKey\expandafter\file@Write{\expandafter\choiceLetter{\arabic{Iteration@printChoices}}}\fi}
            }
            {% If it isn't flagged as correct, we will set the correct flag to false.
            \expandafter\def\csname \Roman{choiceEnvNum}choice\roman{choiceNum}\endcsname{#2}
            }
            \ignorespaces
    }% End of \choice code.




%%% Base idea code to track width manually of hfill. May need to use this to correctly determine the qb@xlen variable in the case where we want to add another in-line option that may or may not exceed the current length.

%\newdimen\usedhfill
%\setbox0=\hbox{a{}b{}c{}d}
%\usedhfill=\hsize
%\advance\usedhfill by -\wd0
%\divide\usedhfill by 3




\newsavebox\choicebox
\newskip\choicesep% separation between choices (glue)
\choicesep=2em plus 100fil
\renewcommand{\thechoiceEnvNum}{\Roman{choiceEnvNum}}
\renewcommand{\thechoiceNum}{\Alph{choiceNum}}
\renewcommand{\theIteration@printChoices}{\Alph{Iteration@printChoices}}

\providecommand{\printChoices}{% \printChoices is an internal macro to print the choices at the end of a MCChoice environment, depending on if we want them shuffled or not.

    %First, we make the call vector based on if we are shuffling these or not.
    \ifshuffleChoices% If we are shuffling, then shuffle up the call
    \make@Vector[InnerShuffle=true]{choiceLoc}{1}{\arabic{choiceNum}}{\arabic{choiceNum}}
    \else% Otherwise, display them in original first to last order.
    \make@Vector[InnerShuffle=false, Order@Direction=forward]{choiceLoc}{1}{\arabic{choiceNum}}{\arabic{choiceNum}}
    \fi	
    
	% Now print the results:
	\savebox\choicebox{}%
    \stepcounter{choiceNum}% Step counter for the < symbol in foreloop.
    
    
    \forloop{Iteration@printChoices}{1}{\arabic{Iteration@printChoices}<\arabic{choiceNum}}{% Begin forloop
            \sbox0{{\bfseries\theIteration@printChoices)}\space
                   \csname \thechoiceEnvNum choice\expandafter\roman{choiceLoc\Roman{Iteration@printChoices}}\endcsname}%
                    \ifdim \textwidth > \dimexpr \wd\choicebox+\wd0\relax
                    % okay
                        \ifdim \wd\choicebox>0pt
                          \savebox\choicebox{\unhbox\choicebox \hspace{\choicesep}\unhbox0}%
                        \else
                          \setbox\choicebox=\box0
                        \fi
                    \else% too wide
                        \ifdim \wd\choicebox>0pt
                          \par
                          \hangindent=1em
                          \unhbox\choicebox
                        \fi
                        \setbox\choicebox=\box0
                    \fi}%
                \ifdim \wd\choicebox>0pt %last box
                  \par
                  \hangindent=1em
                  \unhbox\choicebox
                  \par
                \fi
                }% End of \printChoices code.

\providecommand{\choiceLetter}[1]{% A simple internal command to print the correct letter.
    \ifnum\numexpr#1\relax=1 A)\fi
    \ifnum\numexpr#1\relax=2 B)\fi
    \ifnum\numexpr#1\relax=3 C)\fi
    \ifnum\numexpr#1\relax=4 D)\fi
    \ifnum\numexpr#1\relax=5 E)\fi
    \ifnum\numexpr#1\relax>5 {?Too many choices?)}\fi
    }% End \choiceLetter code.

\providecommand{\lastChoice}[1]{% This is a \choice command, but it will be forced to be printed last.
        \expandafter\protected@edef\csname \Roman{choiceEnvNum}lastChoice\endcsname{\noexpand{#1}}
    }% End of \lastChoice command.








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%           Front Cover Design Commands     %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\FrontPage}{% This command will print the front page and insert a pseudo-blank page for double sided printing.

    \vspace*{-.8cm}\noindent
    \makebox[0pt][l]{\parbox{.5\textwidth}
    {\includegraphics[width=65mm]{UF_Signature}\\[0mm]\large\sl Department of Mathematics}}
    \vspace{-15mm}
    \hfill
    \begin{tabular}{r}
    \bf \Course \\[.01in]
    \bf Exam \ExamNum\ExamForm \\[.01in]
    \bf \Term{ }\the\year \\ %\hspace{2cm}
    \end{tabular}
    
    \vskip 1in
    \normalsize
    
    \begin{description}
      \item[A.] Sign your bubble sheet on the back at the bottom \underline{in ink}.
      \item[B.] In pencil, write and encode in the spaces indicated:
                \begin{description}
                  \item[1)] Name (last name, first initial, middle initial)
                  \item[2)] UF ID number
                  \item[3)] Section number
                \end{description}
      \item[C.] Under ``special codes'' code in the test ID numbers as shown below.\\
                \SpecSecBubs
      \item[D.] At the top right of your answer sheet, for ``Test Form Code'',
                encode \ExamForm.\\
                \FormCodeBub
      \item[E.] \begin{description}
                  \item[1)] The time allowed is \ExamLength.
                  \item[2)] You may write on the test.
                  \item[3)] Raise your hand if you need more scratch paper or if you have a problem with your test.  DO NOT LEAVE YOUR SEAT UNLESS YOU ARE FINISHED WITH THE TEST.
                  \ExamDescription
                \end{description}
      \item[F.] {\bf KEEP YOUR BUBBLE SHEET COVERED AT ALL TIMES.}
      \item[G.] When you are finished:
                \begin{description}
                  \item[1)] Before turning in your test {\bf check carefully for
                            transcribing errors}.  Any mistakes
                            you leave in are there to stay.
                  \item[2)] You must turn in your scantron and tearoff sheets to your discussion leader or exam proctor.
                            Be prepared to show your picture \underline{I.D. with a legible signature}.
                  \item[3)] The answers will be posted in Canvas within one day after the exam.  Your discussion leader will return your tearoff sheet with your exam score in discussion.  Your score will also be posted in Canvas within one week of the exam.
                \end{description}
    \end{description}
    
    
    \newpage
    \vspace*{0pt}\vfill
    \begin{center}\Large LEFT BLANK FOR DOUBLE SIDED PRINTING\end{center}
    \vfill\vspace*{0pt}
    \newpage
    \pagestyle{fancy}
    \lhead{\Course}
    \chead{Exam \ExamNum}
    \rhead{Form \ExamForm}
    \rfoot{Form \ExamForm}

    }% End of FrontPage Command


\providecommand{\ExamDescription}{}% For added description on the exam.
\providecommand{\ExamLength}{90 minutes}%

\providecommand{\SetExamDescription}[1]{%
    \renewcommand{\ExamDescription}{#1}
    }%
\providecommand{\SetCoordinator}[1]{
    \renewcommand{\Coordinator}{#1}
    }%
\providecommand{\SetInstitution}[1]{%
    \renewcommand{\Institution}{#1}
    }%
\providecommand{\SetCourse}[1]{%
    \renewcommand{\Course}{#1}
    }%
\providecommand{\SetExamForm}[1]{%
    \renewcommand{\ExamForm}{#1}
    }%
\providecommand{\SetExamNum}[1]{%
    \renewcommand{\ExamNum}{#1}
    }%
\providecommand{\SetTerm}[1]{%
    \renewcommand{\Term}{#1}
    }%
\providecommand{\SetExamLength}[1]{%
    \renewcommand{\ExamLength}{#1}
    }%

\providecommand{\SpecSecBubs}{% This will display the correct bubbling for the special characters.
    \begin{tabular}{cccccccccc}
           \ifthenelse{\ExamNum=1}{\Large $\bullet$}{1} \ & \ifthenelse{\ExamNum=2}{\Large $\bullet$}{2} \ & \ifthenelse{\ExamNum=3}{\Large $\bullet$}{3} \ & \ifthenelse{\ExamNum=4}{\Large $\bullet$}{4} \ & \ifthenelse{\ExamNum=5}{\Large $\bullet$}{5} \ & \ifthenelse{\ExamNum=6}{\Large $\bullet$}{6} \ & \ifthenelse{\ExamNum=7}{\Large $\bullet$}{7} \ & \ifthenelse{\ExamNum=8}{\Large $\bullet$}{8} \ & \ifthenelse{\ExamNum=9}{\Large $\bullet$}{9} \ & \ifthenelse{\ExamNum=10}{\Large $\bullet$}{0} \\
           \compareStrings{\ExamForm}{A}{\Large $\bullet$}{1} \ & \compareStrings{\ExamForm}{B}{\Large $\bullet$}{2} \ & \compareStrings{\ExamForm}{C}{\Large $\bullet$}{3} \ & \compareStrings{\ExamForm}{D}{\Large $\bullet$}{4} \ & \compareStrings{\ExamForm}{E}{\Large $\bullet$}{5} \ & 6 \ & 7 \ & 8 \ & 9 \ & 0
    \end{tabular}
    }% End of \SpecSecBubs
    
\providecommand{\FormCodeBub}{% This will display the correct bubbling for the form code.
    \begin{tabular}{ccccc}
      \compareStrings{\ExamForm}{A}{\Large $\bullet$}{A} \ & \compareStrings{\ExamForm}{B}{\Large $\bullet$}{B} \ & \compareStrings{\ExamForm}{C}{\Large $\bullet$}{C} \ & \compareStrings{\ExamForm}{D}{\Large $\bullet$}{D} \ & \compareStrings{\ExamForm}{E}{\Large $\bullet$}{E}
    \end{tabular}
    }%


\newenvironment{freeresponse}[1][Test]
    {% Start of start-environment code
        \newpage
        \strictpagecheck
        \checkoddpage
        \ifoddpage% If we're already on an odd page, then we're all set.
        \else% Otherwise, we need a new page.
          \vspace*{0pt}\vfill
          \begin{center}\Large LEFT BLANK FOR DOUBLE SIDED PRINTING\end{center}
          \vfill\vspace*{0pt}
          \newpage
        \fi
        
            \lhead{\Course \\[5pt] \textbf{Name:} }
            \chead{Exam \ExamNum \\[5pt] \hspace*{7cm}\textbf{Section:}}
            \rhead{Form \ExamForm \\[5pt]}
        \noindent\textbf{Signature:} \hspace{8.45cm} \textbf{UFID:} \hrule
        
        
        \begin{center}
        \underline{\large YOU MUST \textbf{SHOW ALL WORK} TO GET CREDIT!}
        \end{center}
        
        \vspace*{4pt}

    }% End of start-environment code
    {% Start of end-environment code
    
    }%End of end-environment code
\newcounter{FRQnum}
\setcounter{FRQnum}{0}
\newenvironment{FRQ}% This is an environment for EACH Free response question.
    [1][Remember to show all work!]% Optional argument contains any special instructions.
    {% Start of environment-start code.
        \stepcounter{FRQnum}% Step the number for a new question number.
        \if\relax\detokenize{#1}\relax% Test to see if we have/need instructions for this FRQ.
            % If the instructions section is blank, that means the instructor forced it blank (default is not blank) so we display nothing.
            \else% Otherwise we have instructions
            \textbf{Instructions:} #1
            \fi%
            
        \begin{enumerate}% Now display the problem as an item with the correct problem number for the FRQ section.
        \item[\textbf{\arabic{FRQnum})}]
        
    }% End of enviroment-start code.
    {% Start of environment-end code.
        \end{enumerate}% End the enumeration for problem number (but we track problem number in the FRQnum counter)
        \newpage% Every FRQ should be on it's own page.
    }% End of environment-end code.


\newcommand{\writeKey}{
    \ifgenAnsKey
        \file@Initialize
    \fi
    }



\ProcessOptions\relax% May want to ProcessOptions at the end in order to renew commands at the end.



