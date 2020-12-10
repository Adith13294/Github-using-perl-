#!/usr/bin/perl -w

use File::Copy;
use File::Compare;
use Scalar::Util qw(looks_like_number);
use Cwd;

if($#ARGV == -1){
$input="UDNEAT";
} else {
$input=$ARGV[0];
}
$version=0;


sub What_is_the_latest_version{
	while ( -e ".legit/.git/.$version" ){
		$version++;
	}
	return $version;
}

sub CheckIdenticalFiles {

	if (compare("$_[0]","$_[1]") == 0){
		return 1;
	} else {
		return 0;
	}
}

sub Does_legit_exists {
	if (! -e ".legit"){
		print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n"; 
		exit 1;
	}

}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub check_if_commit_exists {
	if (! -e ".legit/.git/.0"){
		print STDERR "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	}
}

#INIT 
if($input eq "init"){

	if (! -e ".legit"){
		mkdir (".legit");
		mkdir (".legit/.git");
		mkdir (".legit/.git/.branches");
		mkdir (".legit/.git/.branches/master");
		mkdir (".legit/.git/.index");

		open (PFILE,">",".legit/.git/present_branch.txt");
			my $dir=getcwd; 
			print PFILE ("$dir/.legit/.git/.branches/master");
		close PFILE;


		open (FILE,">",".legit/.git/log_file.txt");
		close FILE;
		print "Initialized empty legit repository in .legit\n";
		
	}else{
		print("legit.pl: error: .legit already exists\n");
	}

#ADD
}elsif ($input eq "add"){
	Does_legit_exists();
	#open (FILE,'<',".legit/.git/present_branch.txt");
		
	#	while($line = <FILE>){
	#		$present_branch=$line;
	#		last;
	#	}
		

	shift @ARGV;

	foreach $file(@ARGV){
		if (! -e "$file"){
				if(-e ".legit/.git/.index/$file"){
					unlink (".legit/.git/.index/$file");
				} else {
					print ("legit.pl: error: can not open '$file'\n"); 
					exit 1;
				}
		} else{
			copy ("$file",".legit/.git/.index/$file");
	#		copy ("$file","$present_branch");		
		}
		
	}
	

#COMMIT
}elsif ($input eq "commit"){
	Does_legit_exists();
	
	$dir=".legit/.git/.index";
	opendir DIR, $dir or die "cannot open dir $dir: $!";
	my @file2 = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;

	open (FILE,'<',".legit/.git/present_branch.txt");
		while($line = <FILE>){
			$present_branch=$line;
			last;
		}

	
	$allFlag=0;
	shift @ARGV;
	$flag = shift @ARGV;
	if ("$flag" eq "-a"){
		$allFlag=1;
		$flag=shift @ARGV;
	}
	if ("$flag" eq "-m"){
		$message=shift @ARGV;
	}
	 else {
		print "usage: <command> <mode> <message>";
		exit 1;
	}

	
	$version = What_is_the_latest_version();
	$old_version = $version-1;	
	
	
	if ($allFlag == 1){
		foreach $file(@file2){
			if (-e $file){
				copy("$file",".legit/.git/.index/$file");
			}
		}
	}

	$setSomethingCommitFlag=0;
	foreach $file(@file2){
		if (-e ".legit/.git/.$old_version/$file"){
			if (compare (".legit/.git/.index/$file",".legit/.git/.$old_version/$file") != 0){
				$setSomethingCommitFlag=1;		
				last;
			}
		} else {
			$setSomethingCommitFlag=1;
			last;
		}	
	}
	if (-e ".legit/.git/.$old_version"){
		$dir=".legit/.git/.$old_version";
		opendir DIR, $dir or die "cannot open dir $dir: $!";
			my @file3 = (grep !/^[.][.]?$/,readdir(DIR));
		closedir DIR;
		foreach $file(@file3){
			if(! -e ".legit/.git/.index/$file"){
				$setSomethingCommitFlag=1;
				last;
			}
		}
	} elsif ((! -e ".legit/.git/.$old_version") && (! @file2)){
		print STDERR "nothing to commit\n";
		exit 1;
	}


	if($setSomethingCommitFlag ==1){

		mkdir ".legit/.git/.$version";
		foreach $file(@file2){
			copy(".legit/.git/.index/$file",".legit/.git/.$version/$file");
			copy(".legit/.git/.index/$file","$present_branch/$file");
			}
		open (TEMP_FILE,">>",".legit/.git/.log_temp");
		open (FILE,"<",".legit/.git/log_file.txt");
		print TEMP_FILE "$version $message\n";	
		while ($line = <FILE>){
			print TEMP_FILE "$line";
		}
		close FILE;
		close TEMP_FILE;
		copy (".legit/.git/.log_temp",".legit/.git/log_file.txt");
		unlink ".legit/.git/.log_temp";
		print("Committed as commit $version\n");
	} else {
		print STDERR ("nothing to commit\n");
	}


#log
} elsif ($input eq "log"){
	Does_legit_exists();
	check_if_commit_exists();

	open FILE,"<",".legit/.git/log_file.txt";
	while ($line = <FILE>){
		print "$line";
	}



#show
} elsif ($input eq "show"){
	
	Does_legit_exists();
	check_if_commit_exists();

	#check arguments
	if ($#ARGV+1 !=2){
		print("Usage: <commit:filename>");
		exit 1;
	}

	$variable=$ARGV[1];
	#split string and check if first argument is a number
	my @expression = split ":",$variable;
	if ($expression[0] ne "" && !looks_like_number($expression[0])){
		print("Usage: Should be a number");
		exit
	}
	
	#if first argument is empty print all the file records where the file is found
	if ($expression[0] eq ""){
		$dir=".legit/.git/.index";
		opendir DIR, $dir or die "cannot open dir $dir: $!";
			if ( -e ".legit/.git/.index/$expression[1]"){	
				open FILE,'<',".legit/.git/.index/$expression[1]" or die "File doesn't exist";
				while ($line = <FILE>){
					print "$line";
				}
				close FILE;
			} else {
				print STDERR ("legit.pl: error: '$expression[1]' not found in index\n");
			}
	}	
		
	#print the record where the file is found
	else{
		if ( -e ".legit/.git/.$expression[0]"){

			if (-e ".legit/.git/.$expression[0]/$expression[1]"){
				open FILE,'<',".legit/.git/.$expression[0]/$expression[1]" or die "File doesn't exist";
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
	


} elsif ($input eq "rm"){

	Does_legit_exists();
	check_if_commit_exists();
	

	shift @ARGV;
	$forceFlag = 0;
	$cacheFlag = 0;
	if ($ARGV[0] eq "--force"){
		$forceFlag = 1; 
		shift @ARGV;
		if ($ARGV[0] eq "--cached"){
			$cacheFlag = 1;
			shift @ARGV;
		}

	}elsif ($ARGV[0] eq "--cached"){
		$cacheFlag = 1;
		shift @ARGV;
		if ($ARGV[0] eq "--force"){
			$forceFlag = 1; 
			shift @ARGV;
		}
	}

	$version = What_is_the_latest_version();
	$old_version=$version-1;


		foreach $file(@ARGV){
		#index deletion
		#local file deletion

			$ValWI=CheckIdenticalFiles("$file",".legit/.git/.index/$file");
			$ValWR=CheckIdenticalFiles("$file",".legit/.git/.$old_version/$file");
			$ValIR=CheckIdenticalFiles(".legit/.git/.index/$file",".legit/.git/.$old_version/$file");

			if ($forceFlag == 1){
				if ( -e ".legit/.git/.index/$file" ){
					unlink ".legit/.git/.index/$file";
					if ($cacheFlag == 1){
						next;
					}

				} else{
						print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
						exit 1;
				}
			
				if (-e "$file"){
					unlink "$file";						
					next;
					} else {
						print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
						exit 1;
					}
			}

			if($forceFlag ==0){
				if($cacheFlag == 0){
					if (-e "$file"){
							if(-e ".legit/.git/.$old_version/$file"){
								if ( -e ".legit/.git/.index/$file" ){
										#print("$ValWI $ValWR $ValIR\n");
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
										unlink "$file" or die "can't delete it";
									}
								} else {
									print STDERR ("legit.pl: error: '$file' has changes staged in the local directory\n");
									exit 1;	
									#unlink "$dir/$file" or die "can't delete it";
								}	
							} elsif ($ValWI == 1) {
								print STDERR ("legit.pl: error: '$file' has changes staged in the index\n");
								exit 1;
								#unlink ".legit/.git/.index/$file" or die "can't delete it";
							} 
				 
					} else {
							print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
							exit 1;
						}	
					}
				

				if (-e ".legit/.git/.index/$file"){
					#print ("$ValWI $ValIR $ValWR\n");
					if( -e ".legit/.git/.$old_version/$file"){
						if ( -e "$file" ){						
							if (($ValIR == 0) && ($ValWI ==0)){
								print STDERR ("legit.pl: error: '$file' in index is different to both working file and repository\n");
								exit 1;
							} if (($ValIR == 0) && ($ValWI ==1)){
								unlink ".legit/.git/.index/$file" or die "can't delete it";
								next;
							} elsif (($ValIR == 1) || ($ValWI == 1)) {
								unlink ".legit/.git/.index/$file" or die "can't delete it";
								next;
							}	
						} elsif ($ValIR == 1){
								unlink ".legit/.git/.index/$file" or die "can't delete it";
								next;
						} elsif ($ValIR == 0){
								print STDERR ("legit.pl: error: '$file' has changes staged in the index\n");
								exit 1;
						}
					} elsif ($ValWI == 1){
						unlink ".legit/.git/.index/$file" or die "can't delete it";
								next;
					}  	 							
				} else{
					print STDERR ("legit.pl: error: '$file' is not in the legit repository\n");
					exit 1;
				}			
			}
		}

} elsif ($input eq "status"){
	
	Does_legit_exists();
	check_if_commit_exists();
	
	$version = 0;
	$version = What_is_the_latest_version();
	$version-=1;

	$dir=getcwd;

	opendir DIR, $dir or die "cannot open dir $dir: $!";
	@Files = (grep !/^[.][.]?$|^.legit/,readdir(DIR));
	closedir DIR;

	
	$dir= ".legit/.git/.index/";

	opendir DIR, $dir or die "cannot open dir $dir: $!";
	@Files1 = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;


	$dir = ".legit/.git/.$version/";
	opendir DIR, $dir or die "cannot open dir $dir: $!";
	@Files2 = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;


	push (@Files,@Files1);
	push (@Files,@Files2);
	my @Files=uniq(@Files);
	@Files = sort(@Files);
	foreach $file(@Files){
		if ( -e "$file"){
			if ( -e ".legit/.git/.index/$file" ){
				if ( -e ".legit/.git/.$version/$file" ){
					if ((compare ("$file",".legit/.git/.index/$file") == 0) && (compare ("$file",".legit/.git/.$version/$file") !=0)){
							print("$file - file changed, changes staged for commit\n" );
						} elsif ((compare ("$file",".legit/.git/.index/$file") != 0) && (compare (".legit/.git/.index/$file",".legit/.git/.$version/$file") != 0) && (compare ("$file",".legit/.git/.$version/$file") != 0)){
							print("$file - file changed, different changes staged for commit\n" );
						} elsif ((compare ("$file",".legit/.git/.index/$file") != 0) && (compare (".legit/.git/.index/$file",".legit/.git/.$version/$file") == 0) && (compare ("$file",".legit/.git/.$version/$file") != 0)){
							print("$file - file changed, changes not staged for commit\n" );
						} elsif ((compare ("$file",".legit/.git/.index/$file") == 0) && (compare (".legit/.git/.index/$file",".legit/.git/.$version/$file") == 0) && (compare ("$file",".legit/.git/.$version/$file") == 0)){
							print("$file - same as repo\n" );
						}
					} else {
					print("$file - added to index\n" );
				}	
			} else {
				print("$file - untracked\n" ); 
			}
				
		} elsif((! -e ".legit/.git/.index/$file") && (! -e "$file")) {
			print("$file - deleted\n" );

		} elsif(( -e ".legit/.git/.index/$file") && (! -e "$file")) {
			print("$file - file deleted\n" );

		}
	}

} elsif ($input eq "branch"){

	Does_legit_exists();
	check_if_commit_exists();

	shift @ARGV;
	$location=getcwd;
	$current_location="$location/.legit/.git/.branches";

	if ($#ARGV==-1){
		opendir DIR, $current_location or die "cannot open dir $dir: $!";
		my @directories = (grep !/^[.][.]?$/,readdir(DIR));
		closedir DIR;
		@directories = sort @directories;
		foreach $dir_name(@directories){
			print ("$dir_name\n");
		}
	exit 1;
	}

	if($ARGV[0] eq "-d"){
		shift @ARGV;
		foreach $dir(@ARGV){
			if ($dir eq "master"){
				print STDERR ("legit.pl: error: can not delete branch 'master'\n");
				exit 1;
			} elsif (! -e ".legit/.git/.branches/$dir"){
				print STDERR ("legit.pl: error: branch '$dir' does not exist\n");
				exit 1;
			} else {
				rmdir ".legit/.git/.branches/$dir";
				print ("Deleted branch '$dir'\n");
				exit 1;
			}
		}



	} else {
		foreach $new_dir(@ARGV){
			if (! -e "$location/.legit/.git/.branches/$new_dir" ){
				mkdir ("$location/.legit/.git/.branches/$new_dir");

			} else {
				print STDERR ("legit.pl: error: branch '$new_dir' already exists\n");
				exit 1;
			}
			
		}
	}

} elsif ($input = "checkout"){

	Does_legit_exists();
	check_if_commit_exists();
	
	if ($#ARGV != 1){
		print STDERR ("usage: legit.pl checkout <branch>\n");
		exit 1;
	}

	shift @ARGV;
	$branch_name=$ARGV[0];
	$version = What_is_the_latest_version();
	$old_version = $version -1;
	$posV=0;
	$raise_unsaved_flag=0;
	$dir=getcwd;

	open (FILE,'<',".legit/.git/present_branch.txt");
		while($line = <FILE>){
			$present_branch=$line;
			last;
		}

	if ("$present_branch" eq "$dir/.legit/.git/.branches/$branch_name"){
		print STDERR "Already on '$branch_name'\n";
		exit 1;

	} elsif (! -e ".legit/.git/.branches/$branch_name"){
		print STDERR ("legit.pl: error: unknown branch '$branch_name'\n");
		exit 1;
	}

	opendir DIR, $dir or die "cannot open dir $dir: $!";
	my @files_at_this_directory = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
	closedir DIR;

	foreach $file (@files_at_this_directory){
		if(-e ".legit/.git/.$old_version/$file"){
				if (CheckIdenticalFiles("$file",".legit/.git/.$old_version/$file") == 0){
					@different[$posV++]="$file";
					$raise_unsaved_flag =1;
				}
			} 	
	}

	if ($raise_unsaved_flag ==1){
		print STDERR ("legit.pl: error: Your changes to the following files would be overwritten by checkout:\n");
		foreach $upd (@different){
			print ("$upd\n");
		}
		exit 1;
	}

	#clear Index

	opendir DIR, ".legit/.git/.index" or die "cannot open dir $dir: $!";
	my @index_files = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;

	foreach $iFile(@index_files){
		unlink ".legit/.git/.index/$iFile";
	}

	#unlink main files

	opendir DIR, $dir or die "cannot open dir $dir: $!";
	@files_at_this_directory = (grep !/^[.][.]?$|^legit.pl$|.legit$|^diary.txt$/,readdir(DIR));
	closedir DIR;

	foreach $lFile (@files_at_this_directory){
		print("$lFile\n");
		if(-e ".legit/.git/.$old_version/$lFile"){
			unlink "$lFile";	
		}
	}	

	open (PFILE,">",".legit/.git/present_branch.txt");
			$dir_file=getcwd; 
			print PFILE ("$dir_file/.legit/.git/.branches/$branch_name");
	close PFILE;

	opendir DIR, ".legit/.git/.branches/$branch_name" or die "cannot open dir $dir: $!";
	my @newFiles = (grep !/^[.][.]?$/,readdir(DIR));
	closedir DIR;
	
	foreach $nFile (@newFiles){
		copy (".legit/.git/.branches/$branch_name/$nFile","$nFile");
		}	

	print("Switched to branch '$branch_name'\n");


} elsif ($input = "UDNEAT"){
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