#!/usr/bin/perl -w

use File::Copy;
use File::Compare;
use Cwd;
use File::Basename;

# Displays legit help
sub legit_help{
	print ("Usage: legit.pl <command> [<args>]\n");
	print("\n");
	print("These are the legit commands:\n");
	print("   init       Create an empty legit repository\n");
	print("   add        Add file contents to the index\n");
	print("   commit     Record changes to the repository\n");
	print("   log        Show log commit\n");
	print("   show       Show file at a particular state\n");
	print("   rm         Remove files from the current directory and from the index\n");
	print("   status     Show the status of files in the current directory, index, and  repository\n");
	print("   branch     list, create or delete a branch\n");
	print("   checkout   Switch branches or restore current directory files\n");
	print("   merge      Join two development histories together\n");
}


#Initialises the legit repository by creating various directories which are required for overall implementation of legit
sub init{

	########################Local Variables Definition###########################################
	my $working_directory=getcwd;
	my $local_legit = "$working_directory/.legit/.git"; 
	#############################################################################################

	if (! -e ".legit"){
		#creates various directories if legit does not exist
		mkdir (".legit");
		mkdir ("$local_legit");
		mkdir ("$local_legit/.branches");
		mkdir ("$local_legit/.branches/master");
		mkdir ("$local_legit/.index");
		mkdir ("$local_legit/.logs");
		mkdir ("$local_legit/.logs/master");
		mkdir ("$local_legit/.indexes");
		mkdir ("$local_legit/.indexes/master");

		#Creation of main branch "master" Which is used for various computation 
		open (PFILE,">","$local_legit/present_branch.txt");
			print PFILE ("$local_legit/.branches/master");
		close PFILE;

		#We will create a log file to open up for master program
		open (FILE,">","$local_legit/.logs/master/.log_file.txt");
		close FILE;

		#We will create a log file to open up for master program
		open (FILE,">","$local_legit/.logs/master/.last_commit.txt");
		close FILE;

		print "Initialized empty legit repository in .legit\n";

	}else{
		print("legit.pl: error: .legit already exists\n");
	}
}

#Subroutine to manage the add function , which adds the file from the working directory to the repository
sub add {
	########################Local Variables Definition###########################################
	my $working_directory = getcwd;
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	##########################################Directory Readings##################################
	#For each file add it from the working repository to the index
	foreach $file(@ARGV){
		#if file does not exists in the working directory but exists in the index then delete it from the index
		if (! -e "$file"){
			if(-e "$local_legit_index/$file"){
				unlink ("$local_legit_index/$file");
			}
		} else{
			copy ("$file","$local_legit_index/$file");
		}
	}
}

#Subroutine to perform commit of files from index to repository
sub commit {

	#Declaring  flags for -a and error issues. Also determinng present branch and previous and current version of backup
	#Declare flag for if commit has to be done

	########################Local Variables Definition###########################################
	my $working_directory = getcwd;
	my $allFlag = 0;
	my $error_Flag = 0;
	my $version = What_is_the_latest_version();
	my $old_version = $version - 1;	
	my $setCommitFlag = 0;
	my $present_branch = present_branch_function();
	my $present_dir = fileparse($present_branch); 
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	my $local_legit_logs = "$working_directory/.legit/.git/.logs";
	##########################################Directory Readings##################################

	$dir="$local_legit_index";
	opendir DIR, $dir or die "cannot open dir $dir: $!";
		my @files_from_index = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;
	##############################################################################################
	
	#To see which flags are requested by tbe user , if -a then add+commit else simply commit	
	if ($#ARGV > 2 || $#ARGV == -1){
		print STDERR ("usage: $file_name commit [-a] -m commit-message\n");
		exit 1;
	}

	$flag = shift @ARGV;
		if ($flag eq "-a"){
			$allFlag = 1;
			if ($#ARGV != 1){
				print STDERR ("usage: $file_name commit [-a] -m commit-message\n");
				exit 1;
			}
			$flag = shift @ARGV;
		}

		if ($flag eq "-m"){
			if ($#ARGV == -1 || $#ARGV > 0){
				print STDERR ("usage: $file_name commit [-a] -m commit-message\n");
				exit 1;	
			}
			
			$message = shift @ARGV;
			if ($message =~ /^[\-\#\$\;\?\<\>]/){
				$error_Flag = 1;
			}
		}
	 	else {
	 		$error_Flag = 1;
		}
	 

	#if we encounter a set error_flag we got an error in the user input
	if ($error_Flag == 1){
		print STDERR ("usage: $file_name commit [-a] -m commit-message\n");
		exit 1;
	}
	
	#if $allFlag is set then we do add+commit so we first update the file to the index, those files which are already in the index
	if ($allFlag == 1){
		foreach $file(@files_from_index){
			if (-e $file){
				copy("$file","$local_legit_index/$file");
			}
		}
	}

	
	#check if the files at the index to be committed are differnt from the last commit, if then set $setCommitFlag. 
	foreach $file(@files_from_index){
		if (-e "$local_legit/.$old_version/$file"){
			if (CheckIdenticalFiles("$local_legit_index/$file","$local_legit/.$old_version/$file") == 0){
				$setCommitFlag=1;		
				last;
			}
		#if the files do not exist then set $setCommitFlag.
		} else {
			$setCommitFlag=1;
			last;
		}	
	}

	#check if files have to be committed as a result of file being deleted using linux command rm, otherwise print nothing to be committed
	if (-e "$local_legit/.$old_version"){
		$dir="$local_legit/.$old_version";
		opendir DIR, $dir or die "cannot open dir $dir: $!";
			my @files_from_last_commit = (grep !/^[.][.]?$/,readdir(DIR));
		closedir DIR;

		foreach $file(@files_from_last_commit){
			if(! -e "$local_legit_index/$file"){
				$setCommitFlag = 1;
				last;
			}
		}

	} elsif ((! -e "$local_legit/.$old_version") && (! @files_from_index)){
		print STDERR "nothing to commit\n";
		exit 1;
	}


	#Run the commit if $setCommitFlag is set
	if($setCommitFlag == 1){
		#store committed files in the new backup as well as current branch
		
		mkdir "$local_legit/.$version";
		foreach $file(@files_from_index){
			copy("$local_legit_index/$file","$local_legit/.$version/$file");
			copy("$local_legit_index/$file","$present_branch/$file");
			copy("$local_legit_index/$file","$local_legit/.indexes/$present_dir");
			}
		
		#Add to log files the data
		open (TEMP_FILE,">>","$local_legit_logs/.log_temp");
			open (FILE,"<","$local_legit_logs/$present_dir/.log_file.txt");
				print TEMP_FILE "$version $message\n";	
				while ($line = <FILE>){
					print TEMP_FILE "$line";
				}

			close FILE;
		close TEMP_FILE;
		
		#copy temporary file into main log file
		copy ("$local_legit_logs/.log_temp","$local_legit_logs/$present_dir/.log_file.txt");
		unlink "$local_legit_logs/.log_temp";
		
		#Update the last commit for the particular branch
		open (FILE, '>',"$local_legit_logs/$present_dir/.last_commit.txt");
			print FILE "$version";
		close FILE;


		#print committes message along with commit version
		print("Committed as commit $version\n");
	} else {
		print STDERR ("nothing to commit\n");
	}
}

#prints the current log of the branch
sub log_fn {
	#if more than one command is given
	if ($#ARGV > -1){
		print STDERR "usage: $file_name log\n";
		exit 1;
	}
########################Local Variables Definition###########################################
	my $working_directory = getcwd;
	my $present_branch = present_branch_function();
	my $present_dir = fileparse("$present_branch");
	my $local_legit_logs = "$working_directory/.legit/.git/.logs";
##############################################################################################
	
	open FILE,"<","$local_legit_logs/$present_dir/.log_file.txt";
	while ($line = <FILE>){
		print "$line";
	}
}

#This subroutine displays the contents of the index or a particular commit
sub show {
	########################Local Variables Definition###########################################
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";

	#check if the string entered matches with the given requirement
	$commit_Function = shift @ARGV;
	
	#split string and check if first argument is a number
	my @expression = split ":",$commit_Function;
	##############################################################################################

	# Split the input show function to get the value of filename and commit
	if (! defined $expression[1]){
		if (! defined $expression[0]){
			print STDERR "$file_name: error: invalid filename ''\n";
			exit 1;			
		}
	print STDERR "$file_name: error: invalid filename ''\n";
	exit 1;
	} 

	if ($expression[1] !~ /^[a-zA-Z0-9][\-\_\.]*$/){
		print STDERR "$file_name: error: invalid filename '$expression[1]'\n";
		exit 1;
	}


	#if first argument is empty print file from the index
	if ($expression[0] eq ""){
			if ( -e "$local_legit_index/$expression[1]"){	
				open FILE,"<","$local_legit_index/$expression[1]";
					while ($line = <FILE>){
						print "$line";
					}
				close FILE;
			
			} else {
				print STDERR ("$file_name: error: '$expression[1]' not found in index\n");
			}
	}	
		
	#print the record where if it is found at the particular commit otherwise print an error message
	else{

		if ( -e "$local_legit/.$expression[0]"){

			if (-e "$local_legit/.$expression[0]/$expression[1]"){
				open FILE,"<","$local_legit/.$expression[0]/$expression[1]";
					while ($line = <FILE>){
						print "$line";
					}
				close FILE;
			} else {
				print STDERR ("legit.pl: error: '$expression[1]' not found in commit $expression[0]\n");
			}
		} else {
			print STDERR ("legit.pl: error: unknown commit '$expression[0]'\n");
		}
	}
}


#Removes a file from the working directory or index or both
sub rm {
	########################Local Variables Definition###########################################
	#Flags to check whether it is forced or cached
	my $forceFlag = 0;
	my $cacheFlag = 0;
	my $working_directory = getcwd;
	my $version = What_is_the_latest_version();
	my $present_branch = present_branch_function();
	my $present_dir = fileparse("$present_branch");
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	my $val = 0;
	open (FILE,"<","$local_legit/.logs/$present_dir/.last_commit.txt");
		$old_version = <FILE>; #reading out last commit for the particular branch
	close FILE;

	##############################################################################################

	#Various checks to find a flawed input for remove
	if ($#ARGV == -1 ){
		print STDERR ("usage $file_name: rm [--forced] [--commit] <filenames>\n");
		exit 1;
	}

	for $line (@ARGV){
	
		if ($line eq "--force"){
			$forceFlag = 1;
			next; 
		}
		if ($line eq "--cached"){
			$cacheFlag = 1;
			next;
		}

		if ($line =~ /^[\-]+.*$/){
			print STDERR ("usage: $file_name: rm [--force] [--cached] <filenames>\n");
			exit 1;
			}

		if ($line !~ /^[a-zA-Z0-9][\-_\.a-zA-Z0-9]*$/){
			print STDERR ("$file_name: error: invalid filename '$line'\n");
			exit 1;
		}

	
		if ($line =~ /^[a-zA-Z0-9][\-_\.a-zA-Z0-9]*$/){
			@arguments[$val++] = $line;
		}
	}

	#check which files are not there in the delete request
	foreach $file(@arguments){	
		if ( -e "$local_legit_index/$file"){
			if ($cacheFlag == 0){
				if (! -e $file){
					print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
					exit 1;
				}
			}		
		} else {
			print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
			exit 1;
		}
	}

	# First of all check in local file directory and then check in index, various types of checks are made before deleting
	foreach $file(@arguments){
		#Defined as
		#ValWI: Value of Working Directory and Index
		#ValWR: Value of Working Directory and Repository
		#ValIR: Value of Index and Repository
		# if identical then 1 
		# if not same then 0

		$ValWI=CheckIdenticalFiles("$file","$local_legit_index/$file");
		$ValWR=CheckIdenticalFiles("$file","$local_legit/.$old_version/$file");
		$ValIR=CheckIdenticalFiles("$local_legit_index/$file","$local_legit/.$old_version/$file");


		#check for set force flag, if set then delete without any prechecks
		#first from index and next from working directory and also from current branch

		if ($forceFlag == 1){
			if ( -e "$local_legit_index/$file" ){
				unlink "$local_legit_index/$file";
				if ($cacheFlag == 1){
					next;
				}

				} else{
					print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
					exit 1;
				}
			
			if (-e "$file"){
				unlink "$file";						
				unlink "$present_branch/$file";
				next;

				} else {
					print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
					exit 1;
				}
		}

		#if force flag is not set, the  lots of checks are done which are given as
		# error raised if the file in the current directory is different to the last commit
		# error raised if the file in the index is different to the last commit
		# File deleted if it is present in repository
		# File also deleted from index if file is present in working directory and not repository
		# File first deleted in working directory and then the index
		
		if($forceFlag ==0){
			if($cacheFlag == 0){
				
				if (-e "$file"){
					if(-e "$local_legit/.$old_version/$file"){
						if ( -e "$local_legit_index/$file" ){
			
							if (($ValIR == 0) && ($ValWI == 0)){
								print STDERR ("legit.pl: error: '$file' in index is different to both working file and repository\n");
								exit 1;
									
							} if ($ValWR == 0 && $ValIR == 1){
								print STDERR ("legit.pl: error: '$file' in repository is different to working file\n");
								exit 1;
									
							} if ($ValWR == 0 && $ValWI == 1){
								print STDERR ("legit.pl: error: '$file' has changes staged in the index\n");
								exit 1;
														
							} if ($ValWR == 1){
								unlink "$file";
								unlink "$present_branch/$file";
							}
						
						} else {
							print STDERR ("legit.pl: error: '$file' has changes staged in the local directory\n");
							exit 1;	
														}	
					} elsif ($ValWI == 1) {
						print STDERR ("legit.pl: error: '$file' has changes staged in the index\n");
						exit 1;
					} 
				 
				} else {
					print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
					exit 1;
				}	
			}
				
			#File is deleted from index with the same checks as for the working directory
			if (-e "$local_legit_index/$file"){
				if( -e "$local_legit/.$old_version/$file"){
					if ( -e "$file" ){						
			
						if (($ValIR == 0) && ($ValWI ==0)){
							print STDERR ("legit.pl: error: '$file' in index is different to both working file and repository\n");
							exit 1;
			
						} if (($ValIR == 0) && ($ValWI ==1)){
							unlink "$local_legit_index/$file" or die "can't delete it";
							next;
			
						} elsif (($ValIR == 1) || ($ValWI == 1)) {
							unlink "$local_legit_index/$file" or die "can't delete it";
							next;
						}	
			
					} elsif ($ValIR == 1){
						unlink "$local_legit_index/$file" or die "can't delete it";
						next;
					} elsif ($ValIR == 0){
						print STDERR ("legit.pl: error: '$file' has changes staged in the index\n");
						exit 1;
					}
			
				} elsif ($ValWI == 1){
					unlink "$local_legit_index/$file" or die "can't delete it";
					next;
				}  	 							
			
			} else{
				print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
				exit 1;
			}			
		}
	}
}

#Shows the status of the file with respect to working directory,index and repository
sub status {

	########################Local Variables Definition###########################################
	my $working_directory = getcwd;
	my $present_branch = present_branch_function();
	my $present_dir = fileparse("$present_branch");
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	


	open (FILE,"<","$local_legit/.logs/$present_dir/.last_commit.txt");
		my $last_branch_commit = <FILE>;
	close FILE;

	###########################Directories#######################################################
	#Files from working directory, index and last commit on the branch are read to determine the status of the file	
	opendir DIR, $working_directory or die "cannot open dir $working_directory: $!";
		my @Files_from_working_directory = (grep !/^[.][.]?$|^.legit/,readdir(DIR));
	closedir DIR;

	$dir1= "$local_legit_index/";
	opendir DIR, $dir1 or die "cannot open dir $dir: $!";
		my @files_from_index = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;

	if (-e "$local_legit/.$last_branch_commit"){
		$dir2 = "$local_legit/.$last_branch_commit/";
		opendir DIR, $dir2 or die "cannot open dir $dir: $!";
			@Files_from_Last_Version = (grep !/^[.][.]?$/,readdir(DIR));
		closedir DIR;
	}

	#############################################################################################

	#status of each file is determined according to following assumptions:
	#file changed, changes staged for commit if last commit and index/working directory are different
	#file changed, different changes staged for commit if all 3 files are different
	#file changed, changes not staged for commit if working directory and index are different but index and commit is same
	#same as repo if all 3 versions are the same
	#untracked if not in index and repository
	#file deleted - if deleted from working directory but present in index
	#deleted - if not present in index and working directory

	#Defined as
	#ValWI: Value of Working Directory and Index
	#ValWR: Value of Working Directory and Repository
	#ValIR: Value of Index and Repository
	# if identical then 1 
	# if not same then 0

	#Files from all the 3 directories are clubbed together and the uniq of the files is found and status is detemined from the pooled array
	push (@Files_from_working_directory,@files_from_index);
	push (@Files_from_working_directory,@Files_from_Last_Version);

	@Files_from_working_directory=uniq(@Files_from_working_directory);
	@Files_from_working_directory = sort(@Files_from_working_directory);

	
	foreach $file(@Files_from_working_directory){

		$ValWI = CheckIdenticalFiles("$file","$local_legit_index/$file");
		$ValIR = CheckIdenticalFiles("$local_legit_index/$file","$local_legit/.$last_branch_commit/$file");
		$ValWR = CheckIdenticalFiles("$file","$local_legit/.$last_branch_commit/$file");



		if ( -e "$file"){
			if ( -e "$local_legit_index/$file" ){
				if ( -e "$local_legit/.$last_branch_commit/$file" ){
					if (($ValWI == 1) && ($ValWR == 0)){
							print("$file - file changed, changes staged for commit\n" );
						} elsif (($ValWI == 0) && ($ValIR == 0) && ($ValWR == 0)){
							print("$file - file changed, different changes staged for commit\n");
						} elsif (($ValWI == 0) && ($ValIR == 1) && ($ValWR == 0)){
							print("$file - file changed, changes not staged for commit\n" );
						} elsif (($ValWI == 1) && ($ValIR == 1) && ($ValWR == 1)){
							print("$file - same as repo\n" );
						}
					} else {
					print("$file - added to index\n" );
				}	
			} else {
				print("$file - untracked\n" ); 
			}
				
		} elsif((! -e "$local_legit_index/$file") && (! -e "$file")) {
			print("$file - deleted\n" );

		} elsif(( -e "$local_legit_index/$file") && (! -e "$file")) {
			print("$file - file deleted\n" );

		}
	}
}

#Branches to new branches 
sub branch {

	########################Local Variables Definition###########################################

	$working_directory=getcwd;
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	my $local_legit_branch = "$working_directory/.legit/.git/.branches";
	my $local_legit_logs = "$working_directory/.legit/.git/.logs";
	$present_branch = present_branch_function();
	$present_dir = fileparse("$present_branch");
	$Branch_delete = 1;
	##############################################################################################	
	
	#there are three cases if no arguments are provided then print all the branches in the ascending order
	#If a name of branch is provided then create a new branch
	# else if -d is provided the branch while checking for dependencies

	#Displays Branch Files in ascending order
	if ($#ARGV==-1){
	
		opendir DIR, $local_legit_branch or die "cannot open dir $dir: $!";
			my @directories = (grep !/^[.][.]?$/,readdir(DIR));
		closedir DIR;
	

		@directories = sort @directories;
		foreach $dir_name(@directories){
			print ("$dir_name\n");
		}
	exit 1;
	}

	#Deletes Branch when -d is provided, various test cases check for correctness for command.
	#Like name of branch starting with alphanumeric characters
	if($ARGV[0] eq "-d"){
		shift @ARGV;
		if ($#ARGV == -1){
			print STDERR "legit.pl: error: branch name required\n";
			exit 1;
		}

		$dir = shift @ARGV;

		if ($dir eq "-d"){
			while ($dir eq "-d"){
				$dir = shift @ARGV;
			}
		}

		if ($#ARGV > -1){
			print STDERR "usage: $file_name branch [-d] <branch>";
			exit 1;
		}

		if ($dir !~ /^[a-zA-Z0-9][a-zA-Z0-9\-\_]*$/){
			print STDERR "$file_name: error: invalid branch name '$dir'\n";
			exit 1;
		}

		if ($dir =~ /^[0-9]+$/){
			print STDERR "$file_name: error: invalid branch name '$dir'\n";
			exit 1;
		}

		if ($dir eq "master"){
			print STDERR ("legit.pl: error: can not delete branch 'master'\n");
			exit 1;

		} elsif (! -e "$local_legit_branch/$dir"){
			print STDERR ("legit.pl: error: branch '$dir' does not exist\n");
			exit 1;

		} else {
			#if it passes all cases we will go for checking if unmerged changes are present
			#We will first compare files from current branch and the branch to be deleted
			#if the to be deleted branch contains files which have no backup we throw an error

			opendir DIR, "$local_legit_branch/$dir" or die "cannot open dir $dir: $!";
				my @files_to_be_deleted = (grep !/^[.][.]?$/,readdir(DIR));
			closedir DIR;
			
			#Run 2 loops to determin if files in to be deleted branch have committed changes or not
			OUTER_FE: foreach $file (@files_to_be_deleted){
				open FILE_IN,"<", "$local_legit_logs/$present_dir/.log_file.txt";
					INNER_W: while ($line = <FILE_IN>){

						my @string = split " ", $line or die "$file_name: error: invalid object '$line'\n";
						
						if (-e "$local_legit/.$string[0]/$file"){
							if (CheckIdenticalFiles ("$local_legit/.$string[0]/$file","$local_legit_branch/$dir/$file") == 0){
								$Branch_delete = 0;
							} else {
								$Branch_delete = 1;
								last INNER_W;
							}
						} else {
							$Branch_delete = 0;
						}
					}
				#in case a file has changes that have not been commited in the to be deleted branch, then throw an error
				if ($Branch_delete == 0){
					print STDERR ("$file_name: error: branch '$dir' has unmerged changes\n");
					exit 1;
				}
				close FILE;
			}

			#recursively delete all files from the branch and then delete the branch
			foreach $file (@files_to_be_deleted){
				unlink ("$local_legit_branch/$dir/$file");	
			}
			rmdir ("$local_legit_branch/$dir");
			print ("Deleted branch '$dir'\n");
			exit 1;
		}

	} elsif ($ARGV[0] =~ /^[\-]+.*$/){
		print STDERR "usage: $file_name branch [-d] <branch>'\n";
		exit 1;

	} elsif ($ARGV[0] !~ /^[a-zA-Z0-9][a-zA-Z0-9\-\_]*$/){
		print STDERR "$file_name: error: invalid branch name '$ARGV[0]'\n";
		exit 1;
	
	#Creates new branches 
	} else {
		foreach $new_dir(@ARGV){
			#while creating new branch data from parent branch is also copied
			if (! -e "$local_legit_branch/$new_dir" ){

				mkdir ("$local_legit_branch/$new_dir");
				mkdir ("$local_legit_logs/$new_dir");
				mkdir ("$local_legit/.indexes/$new_dir");
				
				opendir DIR, "$present_branch" or die "cannot open dir $dir: $!";
					my @branch_files = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
				closedir DIR;

				foreach $file (@branch_files){
					copy ("$present_branch/$file","$local_legit_branch/$new_dir/$file");
				}

				#similarily parent log is also appended 
				open (FILE,">","$local_legit_logs/$new_dir/.log_file.txt");
				close FILE;
				copy ("$local_legit_logs/$present_dir/.log_file.txt","$local_legit_logs/$new_dir/.log_file.txt");

				#Holds the last commit for this branch, as we would need for merging scenarios
				open (FILE,">","$local_legit_logs/$new_dir/.last_commit.txt");
					open (FILE_IN,"<","$local_legit_logs/$present_dir/.last_commit.txt"); 
						 $last_commit = <FILE_IN>; 
						 print FILE "$last_commit";
					close FILE_IN;
				close FILE;

				#Copies the index for this new branch
				opendir DIR, "$local_legit_index" or die "cannot open dir $dir: $!";
					my @index_files = (grep !/^[.][.]?$/,readdir(DIR));
				closedir DIR;

				foreach $file (@index_files){
					copy ("$local_legit_index/$file","$local_legit/.indexes/$new_dir/$file");
				}

				#Throw an error if the branch already exists
			} else {
				print STDERR ("legit.pl: error: branch '$new_dir' already exists\n");
				exit 1;
			}
			
		}
	}

}


#Switches out to the given branch if exists
sub checkout{

	########################Local Variables Definition###########################################
	my $working_directory=getcwd;
	my $branch_name=$ARGV[0];
	my $posV=0;
	my $raise_unsaved_flag = 0;
	my $present_branch = present_branch_function();
	my $present_dir = fileparse("$present_branch");
	$last_branch_commit = "";
	my $last_branch_commit_present = "";
	my $last_branch_commit_main = "";
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_index = "$working_directory/.legit/.git/.index";
	my $local_legit_logs = "$working_directory/.legit/.git/.logs";
	open (FILE,"<","$local_legit_logs/$present_dir/.last_commit.txt");
		$last_branch_commit = <FILE>;
	close FILE;
	##############################################################################################
	

	#Determine the present branch and if it matches then throw error
	#Secondly determine if the branch exists, if not throw an error
	#If pases make operations for checkout 

	open (FILE,"<","$local_legit/present_branch.txt");
		while($line = <FILE>){
			$present_branch = $line;
			last;
		}

	if ("$present_branch" eq "$local_legit/.branches/$branch_name"){
		print STDERR "Already on '$branch_name'\n";
		exit 1;

	} elsif (! -e "$local_legit/.branches/$branch_name"){
		print STDERR ("legit.pl: error: unknown branch '$branch_name'\n");
		exit 1;
	}


	#Before checkout, check for the file merging by retreiving local directory files
	#compare the files present in  current directory and to be branched directory to ensure no unsaved changes are written out

	opendir DIR, $working_directory or die "cannot open dir $working_directory: $!";
		my @files_at_this_directory = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
	closedir DIR;

	open (FILE,"<","$local_legit_logs/$branch_name/.last_commit.txt");
			$last_branch_commit = <FILE>;
	close FILE;

	open (FILE,"<","$local_legit_logs/$present_dir/.last_commit.txt");
		while($line = <FILE>){
			$last_branch_commit_present = $line;
			last;
		}	
	close FILE;


	if ($last_branch_commit ne ""){
		foreach $file (@files_at_this_directory){
			if ($last_branch_commit_present ne ""){
				if (! -e "$local_legit/.$last_branch_commit_present/$file"){
					if(-e "$local_legit/.$last_branch_commit/$file"){
						if (CheckIdenticalFiles("$file","$local_legit/.$last_branch_commit/$file") == 0){
							@different[$posV++]="$file";
							$raise_unsaved_flag = 1;
						}
					} 	
				}
			}	
		}
	}

	#If so raise an error
	if ($raise_unsaved_flag == 1){
		print STDERR ("legit.pl: error: Your changes to the following files would be overwritten by checkout:\n");
		foreach $upd (@different){
			print ("$upd\n");
		}
		exit 1;
	}

	#When it has no issues with checking out to a new directory , ensure following steps are carried out
	#First remove files from the index which is specific to the current branch
	#next remove files from the local directory which is specific to that current branch
	
	#clear Index with files specific to current branch
	opendir DIR, "$local_legit_index" or die "cannot open index\n";
		my @index_files = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;

	open (FILE,"<","$local_legit_logs/$present_dir/.last_commit.txt");
		$last_branch_commit_main = $line;
	close FILE;


	foreach $iFile (@index_files){
		if ($last_branch_commit_main ne ""){
			if( -e "$local_legit/.$last_branch_commit_main/$iFile"){
				if (-e "$iFile"){
					if ((CheckIdenticalFiles("$local_legit/.$last_branch_commit_main/$iFile", "$local_legit_index/$iFile") == 1) 
						&& (CheckIdenticalFiles("$iFile", "$local_legit_index/$iFile") == 1)){
						unlink "$local_legit_index/$iFile";	
					}
				}
			}
		}
	}
	
	#clear current directory with files specific to current branch

	opendir DIR, $working_directory or die "cannot open dir $working_directory\n";
	@files_at_this_directory = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
	closedir DIR;

	foreach $lFile (@files_at_this_directory){
		if ($last_branch_commit_main ne ""){
			if( -e "$local_legit/.$last_branch_commit_main/$lFile"){
				if (CheckIdenticalFiles("$local_legit/.$last_branch_commit_main/$lFile", "$lFile") == 1){
					unlink "$lFile";	
				}
			}
		}
	}

	open (PFILE,">","$local_legit/present_branch.txt");
			print PFILE ("$local_legit/.branches/$branch_name");
	close PFILE;


	#Coping new Files to the new branch to reflect files attributed to that branch

	opendir DIR, "$local_legit/.branches/$branch_name" or die "cannot open dir \n";
	my @newFiles = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;

	opendir DIR, "$local_legit/.indexes/$branch_name" or die "cannot open dir $working_directory";
	my @newIndexFiles = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;
	


	#Coping file into index with files specific to the current branch
	foreach $iFile (@newIndexFiles){
		if (! -e "$local_legit_index/$iFile"){
			copy ("$local_legit/.indexes/$branch_name/$iFile","$local_legit_index/$iFile");
		}
	}	

	#Coping Files into the current directory with files specific to the current branch
	foreach $nFile (@newFiles){
		if (! -e "$nFile"){
			copy ("$local_legit/.branches/$branch_name/$nFile","$nFile");
		}	
	}

	print("Switched to branch '$branch_name'\n");
}



#merge command merges 2 branches  
sub merge {

	########################Local Variables Definition###########################################
	$working_directory = getcwd;
	$present_branch = present_branch_function();
	$present_dir = fileparse("$present_branch");
	my $local_legit = "$working_directory/.legit/.git"; 
	my $local_legit_logs = "$working_directory/.legit/.git/.logs";
	##############################################################################################

	#First determine the common ancestor to ensure if the files can be merged or not
	mkdir "$local_legit/.temp";
	$last_branch_commit = <FILE>;
	close FILE;

	

	open (FILE_MAIN,"<","$local_legit_logs/$present_dir/.log_file.txt");
	DETLATCOM: while ($line_main = <FILE_MAIN>){
		
		@string_main = split " ", $line_main;
		open (FILE_TMER,"<","$local_legit_logs/$toBranch/.log_file.txt"); 
		while ($line_tmer = <FILE_TMER>){
			@string_tmer = split " ", $line_tmer;
			if ($string_main[0] == $string_tmer[0]){
				$common_parent = $string_main[0];
				last DETLATCOM; 
			}
		}
		close FILE_TMER;
	}
	close FILE_MAIN;


	open (FILE_MAIN, "<","$local_legit_logs/$present_dir/.last_commit.txt");
		$last_commit_main = <FILE_MAIN>;
	close FILE_MAIN;

	open (FILE_TMER,"<","$local_legit_logs/$toBranch/.last_commit.txt");
		$last_commit_tmer = <FILE_TMER>;
	close FILE_TMER;

	#compare file from to be merged directory with the common ancestor and the current directory
	# if the files from all the three directories have conflicting changes then throw an error
	# otherwise merge the file into the present directory
	#we will use hash to store values which cause merge conflict
	opendir DIR, "$local_legit/.$last_commit_tmer" or die "cannot open dir $dir: $!";
		my @tmer_b_files = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
	closedir DIR;
	%errors = ();
	
	if ($common_parent == $last_commit_main){
		foreach $tfile(@tmer_b_files){
			if (! -e  "$working_directory/$tfile"){
				copy ("$local_legit/.$last_commit_tmer/$tfile","$local_legit/.temp/$tfile");	
			} elsif (CheckIdenticalFiles("$working_directory/$tfile","$local_legit/.$common_parent/$tfile") == 1) {
				copy ("$local_legit/.$last_commit_tmer/$tfile","$local_legit/.temp/$tfile");
			} elsif (CheckIdenticalFiles("$working_directory/$tfile","$local_legit/.$common_parent/$tfile") == 0) {
				if (CheckIdenticalFiles("$working_directory/$tfile","$local_legit/.$last_commit_tmer") == 0){
					$errors{$tfile} = 1;
				}
			}	
		}	
	}

	#if the hash element contains even one element then throw an error
	if (%errors){
		print STDERR "$file_name: error: These files can not be merged:\n";
		foreach $key (keys %errors){
			print "$key\n";
		}
		exit 1;

	# if merging doesn't cause any conflict then carry on with processing
	} else {
		#copy files which are not found in present directory into the main directory from temp
		opendir DIR, "$local_legit/.temp" or die "cannot open dir $dir: $!";
			my @temp_files = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
		closedir DIR;
		for $file (@temp_files){
			copy ("$local_legit/.temp/$file","$working_directory/$file");	
				
		}
		#once copied delete the temp folder by first deleting its content and then removing the file
		foreach $file (@temp_files){
			unlink ("$local_legit/.temp/$file");	
		}
		rmdir ("$local_legit/.temp");

		#Next merge the two log files to get the proper output
		#This process is carried out by combining the two log files and sorting it via hash and removing duplicates
		open FILE_tmer,"<","$local_legit_logs/$toBranch/.log_file.txt";
			copy ("$local_legit_logs/$present_dir/.log_file.txt","$local_legit/.temp.file");
			open newFILE, ">>", "$local_legit/.temp.file";
			while ($line = <FILE_tmer>){
				print newFILE "$line";
			}
			close newFILE;
		close FILE_tmer;
		
		%sortFiles=();
		open newFILE, "<", "$local_legit/.temp.file";
		
		while ($line = <newFILE>){
			@string = split " ", $line or die "$file_name: error: invalid object '$line'\n";
			if ( not exists $sortFiles{$string[0]}){
				$sortFiles{$string[0]} = $string[1];
			}
		}
		close newFILE;

		#once sorted and stored in a temp file, store it back it in the present branch log file
		open newFILE, ">", "$local_legit/.temp.file";
		foreach $key (reverse sort (keys %sortFiles)){

			print newFILE "$key $sortFiles{$key}\n";
		}
		close newFILE;
		
		copy ("$local_legit/.temp.file","$local_legit_logs/$present_dir/.log_file.txt");
		unlink "$local_legit/.temp.file";
		print ("Fast-forward: no commit created\n");

	}
}

#returns uniq files to the user
sub uniq {
    my %marked;
    grep !$marked{$_}++, @_;
}

#To check if the legit repository has been created or not, returns with error if it has not been created
sub Does_legit_exists {
	if (! -e ".legit"){
		print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n"; 
		exit 1;
	}

}

# Returns the present working branch
sub present_branch_function{
		open (FILE,"<","$working_directory/.legit/.git/present_branch.txt");
		while($line = <FILE>){
			$present_branch=$line;
			last;
		}
		return $present_branch;
}

#Returns the latest version of the commit to be saved
sub What_is_the_latest_version{
	$version = 0;
	while ( -e "$working_directory/.legit/.git/.$version" ){
		$version++;
	}
	return $version;
}

#Checks if 2 files are the same and returns 1 if they are same or else returns 0
sub CheckIdenticalFiles {

	if (compare("$_[0]","$_[1]") == 0){
		return 1;
	} else {
		return 0;
	}
}

#Throws error if no commit has been made yet
sub check_if_commit_exists {
	if (! -e "$working_directory/.legit/.git/.0"){
		print STDERR "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	}
}


######################CONSTANTS#################################################
$file_name = fileparse("$0");
$working_directory = getcwd;
################################################################################

#Main program

# executes when the user does not enter a command
if ($#ARGV == -1){
	legit_help();
	exit 1;
} 

$command = shift @ARGV;

if ($command eq "init"){
	#if arguments are more then the required input then throw error and exit
	if ($#ARGV > -1){
		print STDERR ("usage: $file_name init\n");
		exit 1;
	}
	init();
} 

#This command adds the files from the working directory to the index
elsif ($command eq "add"){
	#check if legit repository exists or not 
	Does_legit_exists();	
	
	@DUP_ARGV =  @ARGV;
	#check if the any arguments have been given instead of filenames
	foreach $file(@ARGV){
		if ($file =~ /^\-.*$/){
			print STDERR "usage: $file_name add <filenames>\n";
			exit 1;
		}
	}
	foreach $file(@DUP_ARGV){
			#if the file is not valid throw an error
		if (($file !~ /^[a-zA-Z0-9][\-_\.a-zA-Z0-9]*$/)) {
			print STDERR ("$file_name: error: invalid filename '$file'\n");
			exit 1;
		}
		#if files doesn't exist and hence can't be open be open
		elsif (! -e $file){
			if (! -e "$working_directory/.legit/.git/.index/$file"){
				print STDERR "$file_name: error: can not open '$file'\n";
				exit 1;
			}
		}
	}	
	add();
}

#This command adds files to the backup by creating a new version every commit
elsif ($command eq "commit"){
	Does_legit_exists();
	commit();
}

#Displays the log for a particular branch
elsif ($command eq "log"){
	Does_legit_exists();
	check_if_commit_exists();
	log_fn();
}

#This prints the contents of the file
elsif ($command eq "show"){
	
	Does_legit_exists();
	check_if_commit_exists();

	#check arguments matches with the input or not 
	if ($#ARGV != 0){
		print("usage: $file_name show <commit>:<filename>\n");
		exit 1;
	}
	show();
}


#remove removes the file from the working directory,index depending on whether it is cached or forced
elsif ($command eq "rm"){

	Does_legit_exists();
	check_if_commit_exists();
	rm();
}

#provides the status of the files in the working directory index and last commit
elsif ($command eq "status"){
	
	Does_legit_exists();
	check_if_commit_exists();
	status();


#creates branches from present branch 
} elsif ($command eq "branch"){

	Does_legit_exists();
	check_if_commit_exists();

	branch();

#change to a different branch
} elsif ($command eq "checkout"){

	Does_legit_exists();
	check_if_commit_exists();
	# Throws error if branch name is not specified
	if ($#ARGV != 0){
		print STDERR ("usage: $file_name checkout <branch>\n");
		exit 1;
	}
	checkout();
	
#merges two branches together	
} elsif ($command eq "merge"){
	Does_legit_exists();
	check_if_commit_exists();

	#various checks are made to make sure the input to merge is proper
	#in addition it supports 2 versions
	#legit.pl merge branch|commit -m branch_name
	#legit.pl merge -m branch_name branch|commit

	if ($#ARGV == 0 ){
		print STDERR ("legit.pl: error: empty commit message\n");
		exit 1;	
	}

	if ($#ARGV != 2){
		print STDERR ("usage: $file_name merge <branch|commit> -m message\n");
		exit 1;	
	}
	
	my $working_directory = getcwd;
	$unknown = shift @ARGV;
	$argisM = shift @ARGV;
	$message = shift @ARGV;

	
	if ($unknown eq "-m"){
		if ($message =~ /^\-.*$/){
		print STDERR ("usage: $file_name merge <branch|commit> -m message\n");
		exit 1;
		} else {
			$toBranch = $message;
			$message = $argisM;
			if (! -e "$working_directory/.legit/.git/.branches/$toBranch"){
			print STDERR "$file_name: error: unknown branch '$toBranch'\n";
			exit 1;
			}

			merge();
			exit 1;
		}
	
	}
	
	if ($unknown =~ /^\-.*$/){
		print STDERR ("usage: $file_name merge <branch|commit> -m message\n");
		exit 1;
	}

	if ($argisM ne "-m"){
		print STDERR ("usage: $file_name merge <branch|commit> -m message\n");
		exit 1;
	}
	
	if ($message =~ /^[\-]+.*$/){
		print STDERR ("usage: $file_name merge <branch|commit> -m message\n");
		exit 1;
	}

	$toBranch = $unknown;
	if ($toBranch =~ /^[0-9]$/){
		if (! -e "$working_directory/.legit/.git/.$toBranch"){
			print STDERR ("$file_name: error: unknown commit '$toBranch'\n");
			exit 1;	
		}
	}


	if (! -e "$working_directory/.legit/.git/.branches/$toBranch"){
		print STDERR ("$file_name: error: unknown branch '$toBranch'\n");
		exit 1;
	}
	
	merge();

#othwerise if the user enters any other command except from the specified one then throw error
} else {
	print STDERR "$file_name: error: unknown command $command\n";
	legit_help();
}