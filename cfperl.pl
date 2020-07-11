#    Program     : CreoleForth.py
#    Author      : Joseph M. O'Connor
#    Purpose     : A Forth scripting language built on top of Perl
#    Date        : July 2020
#    Predecessors: Creole Forth for Delphi/Lazarus, Creole Forth for Excel,
#                  Creole Forth for JavaScript, Creole Forth for Python,
#                  Creole Forth for C#.

use Class::Struct;
use Clone 'clone';
use strict;

sub trim
{
    my @out = @_;
    for (@out)
    {
        s/\^s+//;
        s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}

struct BasicForthConstants =>
{
    SmudgeFlag => '$',
    ImmediateVocab => '$',
    PrefilterVocab => '$',
    PostfilterVocab => '$',
    CompInParamFieldAction => '$',
    ExecuteAction => '$',
    ExecZeroAction => '$',
    CompLitAction => '$'
};

my $bfc = BasicForthConstants->new(
    SmudgeFlag => "SMUDGED",
    ImmediateVocab => "IMMEDIATE",
    PrefilterVocab => "PREFILTER",
    PostfilterVocab => "POSTFILTER",
    CompInParamFieldAction => "COMPINPF",
    ExecuteAction => "EXECUTE",
    ExecZeroAction => "EXEC0",
    CompLitAction => "COMPLIT"
);

struct CreoleForthBundle =>
{
#    Modules => 'Modules',
    Address => '@',
    Dict    => '%',
    buildPrimitive => '$'
};

my $buildPrimitive = sub
{   
    my ($name, $cf, $cfs, $vocab, $compAction, $help, $cfb) = @_;
    my @params = ();
    my @data = ();
    my @Address = @{$cfb->Address};
    my %Dict = %{$cfb->Dict};
    my $cw = CreoleWord->new(
        NameField => $name,
        CodeField => $cf,
        CodeFieldStr => $cfs,
        Vocabulary => $vocab,
        fqNameField => $name . "." + $vocab,
        CompileActionField => $compAction,
        HelpField => $help,
        PrevRowLocField => scalar(@Address) - 1,
        RowLocField => scalar(@Address),
        LinkField => scalar(@Address) - 1,
        IndexField => scalar(@Address),         
        ParamField => [],
        DataField => [],
        ParamFieldStart => 0      
    );
    $Dict{join(".", $name, $vocab)} = $cw;
    $cfb->Dict(\%Dict);
    push(@Address, $cw); 
    #print scalar(@Address) . "\n";
    $cfb->Address(\@Address);
};

our $cfb1 = CreoleForthBundle->new(
  #  Modules => $modules,
    Address => [],
    Dict    => {},
    buildPrimitive => $buildPrimitive
);

struct GlobalSimpleProps =>
{
    Cfb       => 'CreoleForthBundle',
    DataStack => '@',
    ReturnStack => '@',
    VocabStack  => '@',
    PrefilterStack => '@',
    PostfilterStack => '@',
    PADArea     => '@',
    ParsedInput => '@',
    LoopLabels => '@',
    LoopLabelPtr => '$',
    LoopLabels => '@',
    LoopLabelPtr => '$',
    LoopCurrIndexes =>'@',
    OuterPtr => '$',
    InnerPtr => '$',
    ParamFieldPtr => '$',
    InputArea => '$',
    OutputArea => '$',
    CurrentVocab => '$',
    HelpCommentField => '$',
    SoundField => '$',
    CompiledList => '$',
    BFC => 'BasicForthConstants',
    MinArgsSwitch => '$',
    pause => '$',
    onContinue => '$',
    cleanFields => '$'
};

my $cleanFields = sub
{
    my $gsp = shift;
    @{$gsp->DataStack} = ();
    @{$gsp->ReturnStack} = ();
    my @vs = ();
    push(@vs,@{$gsp->VocabStack});
    if ($vs[$#vs] eq "IMMEDIATE")
    {
        pop(@{$gsp->VocabStack});
    }
};

my $gsp = GlobalSimpleProps->new(
    Cfb => $cfb1,
    DataStack => [],
    ReturnStack => [],
    VocabStack => ['ONLY','FORTH','APPSPEC'],
    PrefilterStack => [],
    PostfilterStack => [],
    PADArea     => [],
    ParsedInput => [],
    LoopLabels => ['I', 'J', 'K'],
    LoopLabelPtr => 0,
    LoopCurrIndexes => [0, 0, 0],
    OuterPtr => 0,
    InnerPtr => 0,
    ParamFieldPtr => 0,
    InputArea => "",
    OutputArea => "",
    CurrentVocab => "",
    HelpCommentField => "",
    SoundField => "",
    CompiledList => "",
    BFC => $bfc,
    MinArgsSwitch => 1,
    pause => 0,
    onContinue => 0,
    cleanFields => $cleanFields
);

{
    package CorePrims;

    our $Title = "Core Primitives Grouping";

    # ( -- ) Do-nothing primitive which is surprisingly useful
    our $doNOP = sub
    {
        # Perl errors out unless there's an instruction in there
        my $x = "In NOP\n";
    };

    # ( n1 n2 -- sum ) Adds two numbers on the stack"
    our $doPlus = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        my $sum = $val1 + $val2;
        push(@{$gsp->DataStack}, $sum);
    };

    # ( n1 n2 -- difference ) Subtracts two numbers on the stack
    our $doMinus = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        my $difference = $val1 - $val2;
        push(@{$gsp->DataStack}, $difference);
    };

    # ( n1 n2 -- product ) Multiplies two numbers on the stack
    our $doMultiply = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        my $product = $val1 * $val2;
        push(@{$gsp->DataStack}, $product);
    };

    # ( n1 n2 -- quotient ) Divides two numbers on the stack
    our $doDivide = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        my $quotient = $val1 / $val2;
        push(@{$gsp->DataStack}, $quotient);
    };

    # ( n1 n2 -- remainder ) Returns remainder of division operation
    our $doMod = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        my $remainder = $val1 % $val2;
        push(@{$gsp->DataStack}, $remainder);
    };

    # ( val --  val val ) Duplicates the argument on top of the stack
    our $doDup = sub
    {
        my $gsp = shift;
        my $val = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val, $val);
    };

    # ( val1 val2 -- val2 val1 ) Swaps the positions of the top two stack arguments
    our $doSwap = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val2, $val1);
    }; 

    # ( val1 val2 val3 -- val2 val3 val1 ) Moves the third stack argument to the top
     our $doRot = sub
    {
        my $gsp = shift;
        my $val3 = pop(@{$gsp->DataStack});        
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val2, $val3, $val1);
    }; 

    # ( val1 val2 val3 -- val3 val1 val2 ) Moves the top stack argument to the third position
    our $doMinusRot = sub
    {
        my $gsp = shift;
        my $val3 = pop(@{$gsp->DataStack});        
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val3, $val1, $val2);       
    };

    # ( val1 val2 -- val2 ) Removes second stack argument
    our $doNip = sub
    {
       my $gsp = shift;
       my $val1 = pop(@{$gsp->DataStack});
       pop(@{$gsp->DataStack});
       push(@{$gsp->DataStack}, $val1);
    };

    # ( val1 val2 -- val2 val1 val2 ) Copies top stack argument under second argument
    our $doTuck = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val2, $val1, $val2);
    };

    # ( val1 val2 -- val1 val2 val1 ) Copies second stack argument to the top of the stack
    our $doOver = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});
        push(@{$gsp->DataStack}, $val1, $val2, $val1);
    };

    # ( val -- ) Drops the argument at the top of the stack
    our $doDrop = sub
    {
        my $gsp = shift;
        pop(@{$gsp->DataStack});
    };

    # ( val -- ) Prints the argument at the top of the stack
     our $doDot = sub
    {
        my $gsp = shift;
        print(pop(@{$gsp->DataStack}));
    };  
 
 
    # ( -- n ) Returns the stack depth   
     our $doDepth = sub
    {
        my $gsp = shift;
        push(@{$gsp->DataStack}, scalar(@{$gsp->DataStack}));
    };   

    # ( -- ) prints out Hello World
    our $doHello = sub
    {  
        print "Hello world\n";
    };

    # ( -- ) prints out Tulip
    our $doTulip = sub
    {
        print "Tulip\n";
    };

# more todo
    # ( -- ) Lists the dictionary definitions
     our $doVList = sub
    {
        my $gsp = shift;
        my @definitionTable;
        my $cw;
        my $dtString;
        push(@definitionTable,  scalar(@{$gsp->Cfb->Address}) . " definitions");
        push(@definitionTable, "Index    Name    Vocabulary    Code Field    Param Field    Data Field   Help Field");
        push(@definitionTable, "-----    ----    ----------    ----------    -----------    ----------   ----------");
        for (my $i = 0; $i < scalar(@{$gsp->Cfb->Address}); $i++)
        {
            my $index = @{$gsp->Cfb->Address}[$i]->IndexField;
            my $nf    = @{$gsp->Cfb->Address}[$i]->NameField;
            my $vocab = @{$gsp->Cfb->Address}[$i]->Vocabulary;
            my $cfs   = @{$gsp->Cfb->Address}[$i]->CodeFieldStr;
            my $pfRef = @{$gsp->Cfb->Address}[$i]->ParamField;
            my @pf    = @{$pfRef};
            my $dfRef = @{$gsp->Cfb->Address}[$i]->DataField;
            my @df    = @{$dfRef};
            my $hf    = @{$gsp->Cfb->Address}[$i]->HelpField;
            push(@definitionTable,"$index      $nf      $vocab      $cfs " . join(",", @pf) . "      " . join(",", @df) . "      " . $hf );
        }

        for (my $i = 0; $i < scalar(@definitionTable); $i++)
        {
            print "$definitionTable[$i]\n";
        }
    };  

    # ( -- ) Prints today's date
    our $doToday = sub
    {
        my ($day, $month, $year) = (localtime)[3, 4, 5];
        printf("%02d-%02d-%04d", $month+1, $day, $year+1900);
    };

    # ( --  time ) Puts the time on the stack
    our $doNow = sub
    {
        (localtime)[3, 4, 5];
        my $gsp = shift;
        push(@{$gsp->DataStack}, localtime);
    };
}

{
    package Interpreter;

    our $Title = 'Interpreter grouping';

    # splits the input into individual words
    our $doParseInput = sub
    {
        my $gsp = shift;
        my @lines = split("\n", $gsp->InputArea);
        foreach (@lines)
        {
            $_ .= " __#EOL#__ ";
        }
        my $codeLine = join(" ", @lines);
        my @code = split(/\s+/, $codeLine);
        push(@{$gsp->ParsedInput},@code);
    };

    # Looks up the word based on its list index and executes whatever is in its code field
    our $doInner = sub
    {
        my $gsp = shift;
        $gsp->ParamFieldPtr(0);
        my @addresses = @{$gsp->Cfb->Address};
        my $cw = @addresses[$gsp->InnerPtr];
        my $cf = $cw->CodeField;
        &{$cf}($gsp);
    };

    # Run-time code for colon definitions
    our $doColon = sub
    {
        my $gsp = shift;
        # $gsp->ParamFieldPtr(0);
        my @Addresses = @{$gsp->Cfb->Address};
        my $currWord = @{$gsp->Cfb->Address}[$gsp->InnerPtr];
        my @paramField = @{$currWord->ParamField};

        while ($gsp->ParamFieldPtr < scalar(@paramField))
        {
            my $addrInPF = $paramField[$gsp->ParamFieldPtr];
            my $codeField = $Addresses[$addrInPF]->CodeField;
            $gsp->ParamFieldPtr($gsp->ParamFieldPtr + 1);
            my $rLoc = ReturnLoc->new(DictAddr => $gsp->InnerPtr, ParamFieldAddr => $gsp->ParamFieldPtr);
            push(@{$gsp->ReturnStack}, $rLoc);
            &{$codeField}($gsp);
            $rLoc = pop(@{$gsp->ReturnStack});
            $gsp->InnerPtr($rLoc->DictAddr);
            $gsp->ParamFieldPtr($rLoc->ParamFieldAddr);
        }
    };

    # ( -- ) Empties the vocabulary stack, then puts ONLY on it
    our $doOnly = sub
    {
        my $gsp = shift;
        @{$gsp->VocabStack} = ();
        push(@{$gsp->VocabStack},"ONLY");
    };

    # ( -- ) Puts FORTH on the vocabulary stack
    our $doForth = sub
    {
        my $gsp = shift;
        @$gsp->VocabStack = ();
        push(@{$gsp->VocabStack},"FORTH");
    };

    # ( -- ) Puts APPSPEC on the vocabulary stack
    our $doAppSpec = sub
    {
        my $gsp = shift;
        @$gsp->VocabStack = ();
        push(@{$gsp->VocabStack},"APPSPEC");
    };

 # Search vocabularies from top to bottom for word. If found, execute. If not, it gets pushed onto the stack
    our $doOuter = sub
    {
        my $gsp = shift;
        my $rawWord = "";
        my $fqWord = "";
        my $isFound = 0;
        $gsp->OuterPtr(0);
        $gsp->InnerPtr(0);
        $gsp->ParamFieldPtr(0);
        my $searchVocabPtr = 0;
        my @vs = @{$gsp->VocabStack};
        my %dict = %{$gsp->Cfb->Dict};

        while ($gsp->OuterPtr < scalar(@{$gsp->ParsedInput}))
        {
            if ($gsp->pause == 0)
            {
                $rawWord = $gsp->ParsedInput->[$gsp->OuterPtr];
                $searchVocabPtr = scalar(@{$gsp->VocabStack}) - 1;
                while ($searchVocabPtr >= 0)
                {
                    $fqWord = uc($rawWord) . "." . $vs[$searchVocabPtr];
                    if (exists $dict{$fqWord})
                    {
                        my $cw = $dict{$fqWord};
                        my $indexField = $cw->IndexField;
                        $gsp->InnerPtr($indexField);
                        &{$doInner}($gsp);
                        $isFound = 1;
                        last;
                    }
                    else
                    {
                        $searchVocabPtr--;
                    }
                }
            }
            if ($isFound == 0)
            {
                push(@{$gsp->DataStack}, $rawWord)
            }
            $gsp->OuterPtr($gsp->OuterPtr + 1);
            $isFound = 0;
        }
        $gsp->PADArea();
    };
  
}

{
    package Compiler;

    our $Title = "Compiler grouping";

    # ( n --) Compiles value off the TOS into the next parameter field cell
    our $doComma = sub
    {
        my $gsp = shift;
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $token = pop(@{$gsp->DataStack});
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        push(@{$newCreoleWord->ParamField}, $token);
        $newCreoleWord->ParamField($newCreoleWord->ParamField);
        $gsp->ParamFieldPtr(scalar($newCreoleWord->ParamField) - 1);
    };

    # Executes at time zero of colon compilation, when CompileInfo triplets are placed in the PAD area.
    # Example : comment handling - the pointer is moved past the comments
    # ( -- ) Single-line comment handling
    our $doSingleLineCmts = sub
    {
        my $gsp = shift;
        my @parsedInput = @{$gsp->ParsedInput};
        while ($parsedInput[$gsp->OuterPtr] !~ /__#EOL#__/)
        {
            $gsp->OuterPtr($gsp->OuterPtr + 1);
        }
    };

    # ( -- ) Multiline comment handling
    our $doParenCmts = sub
    {
        my $gsp = shift;
        my @parsedInput = @{$gsp->ParsedInput};
        while ($parsedInput[$gsp->OuterPtr] !~ /\)/)
        {
            $gsp->OuterPtr($gsp->OuterPtr + 1);
        }
    };

     # ( -- list ) List compiler
     our $compileList = sub
     {   
         my $gsp = shift;
         my @parsedInput = $gsp->ParsedInput;
         my @compiledList = ();
         @{$gsp->CompiledList()} = ();
         $gsp->OuterPtr($gsp->OuterPtr + 1);
         while ($parsedInput[$gsp->OuterPtr] =~ /\}/)
         {
             push(@compiledList, $parsedInput[$gsp->OuterPtr]);
         }
         push(@{$gsp->compiledList},@compiledList);
         my $joinedList = join(" ", @{$gsp->compiledList});
         push(@{$gsp->DataStack}, $joinedList);
     };

     # ( address -- ) Executes the word corresponding to the address on the stack
     our $doExecute = sub
     {
         my $gsp = shift;
         my $address = pop(@{$gsp->DataStack});
         $gsp->InnerPtr($address);
         my $cw = @{$gsp->Cfb->Address}[$address];
         my $codeField = $cw->CodeField;;
         &{$codeField}($gsp);
     };

     # ( -- location ) Returns address of the next available dictionary location
     our $doHere = sub
     {
         my $gsp = shift;
         my $hereLoc = scalar(@{$gsp->Cfb->Address});
         push(@{$gsp->DataStack}, $hereLoc);
     };

     # Used internally by doCreate - is not compiled into the dictionary
      our $doMyAddress = sub
     {
        my $gsp = shift;
        my @Addresses = @{$gsp->Cfb->Address};
        my $cw = $Addresses[$gsp->InnerPtr];
        push(@{$gsp->DataStack}, $cw->IndexField);
     };  

     # CREATE <name>. Adds a named entry into the dictionary  
     our $doCreate = sub
     {
         my $gsp = shift;
         my $hereLoc = scalar(@{$gsp->Cfb->Address});
         my @parsedInput = @{$gsp->ParsedInput};
         my $name = $parsedInput[$gsp->OuterPtr + 1];
         my @Addresses = @{$gsp->Cfb->Address};
         my %Dict = %{$gsp->Cfb->Dict};
         my $help = "TODO: ";
         my $fqName = join(".", $name, $gsp->CurrentVocab);
         my $cw = CreoleWord->new(
             NameField => $name,
             CodeField => $Compiler::doMyAddress,
             CodeFieldStr => "Compiler::doMyAddress", 
             Vocabulary => $gsp->CurrentVocab,
             fqNameField => $fqName,
             CompileActionField => "COMPINPF",
             HelpField => $help,
             PrevRowLocField => $hereLoc - 1,
             RowLocField => $hereLoc,
             LinkField => $hereLoc - 1,
             IndexField => $hereLoc,
             ParamField => [],
             DataField => [],
             ParamFieldStart => 0
         );

         $Dict{$fqName} = $cw;
         push(@Addresses,$cw);
         $gsp->OuterPtr($gsp->OuterPtr + 2);
         $gsp->Cfb->Dict(\%Dict);
         $gsp->Cfb->Address(\@Addresses);
     };  

     sub doLookup
     {
         my ($token, $vsRef, $dictRef) = @_;
         my %dict = %$dictRef;
         my @vs = @$vsRef;
         my $cw;
         my $ci;
         my $found = 0;

         foreach (@vs)
         {
             my $fqName = join(".", $token, $_);
             if (exists $dict{$fqName})
             {
                 $cw = $dict{$fqName};
                 $ci = CompileInfo->new(FQName => $fqName, Address=> $cw->IndexField, CompileAction => $cw->CompileActionField); 
                 $found = 1;        
             }
             else
             {
                 next;
             }
         }
        if ($found == 0)
        {
            $ci = CompileInfo->new(FQName => $token, Address=> $token, CompileAction => "COMPLIT");    
        }
         return $ci;        
     }

    # ( -- ) Starts compilation of a colon definition
    our $compileColon = sub
    {
         my $gsp = shift;
         my $hereLoc = scalar(@{$gsp->Cfb->Address});
         my @parsedInput = @{$gsp->ParsedInput};
         my $name = $parsedInput[$gsp->OuterPtr + 1];
         my @Addresses = @{$gsp->Cfb->Address};
         my %Dict = %{$gsp->Cfb->Dict};
         my @params = ();
         my @data = ();
         my $help = "TODO: ";
         my $rawWord = "";
         my $searchVocabPtr = 0;
         my $isFound = 0;
         my $compAction = "";
         my $compInfo;
         my $isSemiPresent = 0;
         my $colonIndex = -1;
         my $gspComp = GlobalSimpleProps->new(
               Cfb => $gsp->Cfb,
               DataStack => [],
               ReturnStack => [],
               VocabStack => ['ONLY','FORTH','APPSPEC'],
               PrefilterStack => [],
               PostfilterStack => [],
               PADArea     => [],
               ParsedInput => [],
               LoopLabels => ['I', 'J', 'K'],
               LoopLabelPtr => 0,
               LoopCurrIndexes => [0, 0, 0],
               OuterPtr => 0,
               InnerPtr => 0,
               ParamFieldPtr => 0,
               InputArea => "",
               OutputArea => "",
               CurrentVocab => "",
               HelpCommentField => "",
               SoundField => "",
               CompiledList => "",
               BFC => $gsp->BFC,
               MinArgsSwitch => 1,
               pause => 0,
               onContinue => 0,
               cleanFields => $gsp->cleanFields
         );
         my $i = 0;
         my $codeField;
         my $isSemiPresent = 0;
         my $fqName = $name . "." . $gsp->CurrentVocab;

         # Elementary syntax check - if a colon isn't followed by a matching semicolon, you get an error message and the stacks and input are cleared.
         for ($i = 0; $i < scalar(@parsedInput); $i++)
         {
             if ($parsedInput[$i] == ":")
             {
                 $colonIndex = $i;
             }
             if ($parsedInput[$i] == ";")
             {
                 $isSemiPresent = 1;
             }
         }
         if ($isSemiPresent != 1)
         {
             print "Error: colon def must have matching semicolon\n";
             &{$gsp->cleanFields}($gsp);
             return;
         }

        # Compilation is started when the IMMEDIATE vocabulary is pushed onto the vocabulary stack. No need for the usual Forth STATE flag.
        push(@{$gsp->VocabStack}, $gsp->BFC->ImmediateVocab); 
        my $cw = CreoleWord->new(
            NameField => $name,
            CodeField => $Interpreter::doColon,
            CodeFieldStr => "Interpreter::doColon",
            Vocabulary => $gsp->CurrentVocab,
            fqNameField => $name . "." . $gsp->CurrentVocab,
            CompileActionField => "COMPINPF",
            HelpField => $help,
            PrevRowLocField => scalar(@Addresses) - 1,
            RowLocField => scalar(@Addresses),
            LinkField => scalar(@Addresses) - 1,
            IndexField => scalar(@Addresses),         
            ParamField => [],
            DataField => [],
            ParamFieldStart => 0      
        ); 
        # The smudge flag avoids accidental recursion. But it's easy enough to get around if you want to. 
        my $fqNameSmudged = $name + "." . $gsp->CurrentVocab + "." . $gsp->BFC->SmudgeFlag;
        $Dict{$fqNameSmudged} = $cw;
        $gsp->Cfb->Dict(\%Dict);
        push(@Addresses, $fqNameSmudged);

        $gsp->OuterPtr($gsp->OuterPtr + 2);
        # Parameter field contents are set up in the PAD area. Each word is looked up one at a time in the dictionary, and its name, address, and
        # compilation action are placed in the CompileInfo triplet.
        while ($gsp->OuterPtr < scalar(@parsedInput) && 
              @{$gsp->VocabStack}[scalar(@{$gsp->VocabStack}) - 1] eq $gsp->BFC->ImmediateVocab)
        {
            $rawWord = $parsedInput[$gsp->OuterPtr];
            $compInfo = doLookup(uc($rawWord), $gsp->VocabStack, \%Dict);
            if ($compInfo->CompileAction ne $gsp->BFC->ExecZeroAction)
            {
                push(@{$gsp->PADArea}, $compInfo);              
            }
            else
            {
                # This is stuff where the outer ptr is manipulated such as comments
                $codeField = $compInfo->CodeField;
                &{$codeField}($gsp);
            }
            $gsp->OuterPtr($gsp->OuterPtr + 1);
        }    

        # 1. Builds the definition in the parameter field from the PAD area. Very simple; the address of each word appears before its associated
        #    compilation action. Most of the time, it will be COMPINPF, which will simply compile the word into the parameter field (it's actually
        #    , (comma) with a different name for readability purposes).
        #    Compiling words such as CompileIf will execute since that's the compilation action they're tagged with.
        # 2. Attaches it to the smudged definition.
        # 3. "Unsmudges" the new definition by copying it to its proper fully-qualified property and places it in the Address array.
        # 4. Deletes the smudged definition.
        # 5. Pops the IMMEDIATE vocabulary off the vocabulary stack and halts compilation.
        $i = 0;
        @{$gspComp->VocabStack} = ();
        push(@{$gspComp->VocabStack}, @{$gsp->VocabStack});
        push(@{$gspComp->Cfb->Address}, $Dict{$fqNameSmudged});

        # Putting the args and compilation actions together then executing them seems to cause a problem with compiling words.
        # Getting around this by putting one arg on the stack, one in the input area, then executing. 
        my @pa = @{$gsp->PADArea};
        while ($i < scalar(@{$gsp->PADArea}))
        {
            $compInfo = $pa[$i];
            push(@{$gspComp->DataStack}, $compInfo->Address);
            $gspComp->InputArea($compInfo->CompileAction);
            &{$Interpreter::doParseInput}($gspComp);
            &{$Interpreter::doOuter}($gspComp);
            # Need to clean up parsed input between compilations - do I have this in other Creole Forths?
            @{$gspComp->ParsedInput} = ();
            $i++;;
        }

        @{$gspComp->PADArea} = ();
        pop(@{$gspComp->VocabStack});
           
        my @aComp = @{$gspComp->Cfb->Address};
        $cw = $aComp[$hereLoc];
        $Dict{$fqName} = $cw;

        # remove the smudged dictionary entry, empty PAD, assign new dictionary
        delete($Dict{$fqNameSmudged});  
        @{$gsp->PADArea} = ();         
        $gsp->Cfb->Dict(\%Dict); 
    };

     # ( -- ) Terminates compilation of a colon definition
     our $doSemi = sub
     {
        my $gsp = shift;
        # print "Compilation is completed\n";
        my @vs = ();
        foreach(@{$gsp->VocabStack})
        {
            push(@vs, $_) unless $_ eq "IMMEDIATE";
        }
        $gsp->VocabStack(\@vs);
     };

     # ( -- ) Compiles doLit and a literal into the dictionary
     our $compileLiteral = sub
     {
         my $gsp = shift;
         my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
         my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
         my %Dict = %{$gsp->Cfb->Dict};
         my $doLitAddr = $Dict{"doLiteral.IMMEDIATE"}->IndexField;
         my $litVal = pop(@{$gsp->DataStack});
         push(@{$newCreoleWord->ParamField}, $doLitAddr, $litVal);
         $gsp->ParamFieldPtr(scalar(@{$newCreoleWord->ParamField}) - 1);
     };

     # ( -- lit ) Run-time code that pushes a literal onto the stack
     our $doLiteral = sub
     {
         my $gsp = shift;
         my $currWord = @{$gsp->Cfb->Address}[$gsp->InnerPtr];
         my @paramField = @{$currWord->ParamField};
         my $rLoc = pop(@{$gsp->ReturnStack});
         my $litVal = $paramField[$gsp->ParamFieldPtr];
         push(@{$gsp->DataStack}, $litVal);
         $rLoc->ParamFieldAddr($rLoc->ParamFieldAddr + 1);
         $gsp->ParamFieldPtr($rLoc->ParamFieldAddr);
         push(@{$gsp->ReturnStack}, $rLoc);
     };

     # ( addr -- val ) Fetches the value in the param field  at addr
     our $doFetch = sub
     {
         my $gsp = shift;
         my $address = pop(@{$gsp->DataStack});
         my @Addresses = @{$gsp->Cfb->Address};
         my @paramField = @{$Addresses[$address]->ParamField};
         my @dataField = @{$Addresses[$address]->DataField};
         my $storedVal;
         if (scalar(@paramField) > 0)
         {
             $storedVal = @paramField[0];
         }
         if (scalar(@dataField) > 0)
         {
             $storedVal = @dataField[0];
         }
         push(@{$gsp->DataStack}, $storedVal);        
     };

     # ( val addr --) Stores the value in the param field  at addr
     our $doStore = sub
     {
         my $gsp = shift;
         my $address = pop(@{$gsp->DataStack});
         my $valToStore = pop(@{$gsp->DataStack});
         my @Addresses = @{$gsp->Cfb->Address};
         my @paramField = ();
         push(@paramField, $valToStore);    
         $Addresses[$address]->ParamField(\@paramField);    
     };  

    # (  -- ) Sets the current (compilation) vocabulary to the context vocabulary (the one on top of the vocabulary stack)
    our $doSetCurrentToContext = sub
    {
        my $gsp = shift;
        my $currentVocab = @{$gsp->VocabStack}[scalar(@{$gsp->VocabStack}) - 1];
        gsp->CurrentVocab($currentVocab);
        print "Current vocab is now " + $gsp->CurrentVocab + "\n";
    };

    # ( -- ) Flags a word as immediate (so it executes instead of compiling inside a colon definition)
    our $doImmediate = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my $fqName = $newCreoleWord->fqNameField;
        $newCreoleWord->CompileAction($gsp->BFC->ExecuteAction);
        $newCreoleWord->Vocabulary($gsp->BFC->ImmediateVocab);
        @{$gsp->Cfb->Address}[$newRow] = $newCreoleWord;
        $Dict{fqName} = $newCreoleWord;
        $gsp->Cfb->Dict = \%Dict;
    };

    # ( -- location ) Compile-time code for IF
    our $compileIf = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow]; 
        my $zeroBranchWord = $Dict{"0BRANCH.IMMEDIATE"};
        my $zeroBranchAddr = $zeroBranchWord->IndexField;
        push(@{$newCreoleWord->ParamField}, $zeroBranchAddr);        
        push(@{$newCreoleWord->ParamField}, -1);
        $gsp->ParamFieldPtr(scalar(@{$newCreoleWord->ParamField}) - 1);
        push(@{$gsp->DataStack}, $gsp->ParamFieldPtr);
    };

    # ( -- location ) Compile-time code for ELSE
    our $compileElse = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my $jumpWord = $Dict{"JUMP.IMMEDIATE"};
        my $jumpAddr = $jumpWord->IndexField;
        my $elseWord = $Dict{"doElse.IMMEDIATE"};
        my $elseAddr = $elseWord->IndexField;        
        push(@{$newCreoleWord->ParamField}, $jumpAddr, -1);
        my $jumpAddrPFLoc = scalar(@{$newCreoleWord->ParamField}) - 1;
        push(@{$newCreoleWord->ParamField}, $elseAddr);
        my $zeroBrAddrPFLoc = pop(@{$gsp->DataStack});
        my @paramField = @{$newCreoleWord->ParamField};
        $paramField[$zeroBrAddrPFLoc] = scalar(@paramField) - 1;
        push(@{$gsp->DataStack}, $jumpAddrPFLoc);
        $gsp->ParamFieldPtr(scalar(@{$newCreoleWord->ParamField}) - 1);
        $newCreoleWord->ParamField(\@paramField);
    };

    # ( -- location ) Compile-time code for THEN
    our $compileThen = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow]; 
        my $branchPFLoc = pop(@{$gsp->DataStack});
        my $thenWord = $Dict{"doThen.IMMEDIATE"};
        my $thenAddr = $thenWord->IndexField; 
        push(@{$newCreoleWord->ParamField}, $thenAddr);
        my @paramField = @{$newCreoleWord->ParamField};
        $paramField[$branchPFLoc] = scalar(@paramField) - 1;
        $newCreoleWord->ParamField(\@paramField);
    };

    # ( flag -- ) Run-time code for IF
    our $do0Branch = sub
    {
        my $gsp = shift;
        my @Addresses = @{$gsp->Cfb->Address};
        my $currWord = $Addresses[$gsp->InnerPtr];
        my @paramField = @{$currWord->ParamField};
        my $rLoc = pop(@{$gsp->ReturnStack});
        my $jumpAddr = $paramField[$rLoc->ParamFieldAddr];
        my $branchFlag = pop(@{$gsp->DataStack});
        if ($branchFlag == 0)
        {
            $gsp->ParamFieldPtr($jumpAddr);
        }
        else 
        {
            $gsp->ParamFieldPtr($gsp->ParamFieldPtr + 1);
        }
        $rLoc->ParamFieldAddr($gsp->ParamFieldPtr);
        push(@{$gsp->ReturnStack}, $rLoc);
    };

        # ( -- beginLoc ) Compile-time code for BEGIN
    our $compileBegin = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow]; 
        my $beginAddr = $Dict{"doBegin.IMMEDIATE"}->IndexField;
        push(@{$newCreoleWord->ParamField}, $beginAddr);
        my $beginLoc = scalar(@{$newCreoleWord->ParamField}) - 1;
        push(@{$gsp->DataStack}, $beginLoc);
    };

    # ( beginLoc -- ) Compile-time code for UNTIL
    our $compileUntil = sub
    {
        my $gsp = shift;
        my %Dict =  %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my $beginLoc = pop(@{$gsp->DataStack});
        my $zeroBranchAddr = $Dict{"0BRANCH.IMMEDIATE"}->IndexField;
        my @paramField = @{$newCreoleWord->ParamField};
        push(@paramField, $zeroBranchAddr, $beginLoc);
        $newCreoleWord->ParamField(\@paramField);
    };

    # ( -- beginLoc ) Compile-time code for DO
    our $compileDo = sub
    {
        my $gsp = shift;
        my %Dict = %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my @paramField = @{$newCreoleWord->ParamField};
        my $doStartDoAddr = $Dict{"doStartDo.IMMEDIATE"}->IndexField;
        my $doAddr = $Dict{"doDo.IMMEDIATE"}->IndexField;
        push(@paramField, $doStartDoAddr, $doAddr);
        my $doLoc = scalar(@paramField) - 1;
        $newCreoleWord->ParamField(\@paramField);
        push(@{$gsp->DataStack}, $doLoc);
    };

    # ( -- beginLoc ) Compile-time code for LOOP
    our $compileLoop = sub
    {
        my $gsp = shift;
        my %Dict = %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my @paramField = @{$newCreoleWord->ParamField};
        my $loopAddr = $Dict{"doLoop.IMMEDIATE"}->IndexField;
        my $doLoc = pop(@{$gsp->DataStack});
        push(@paramField, $loopAddr, $doLoc);
        $newCreoleWord->ParamField(\@paramField);
    };

    # ( -- beginLoc ) Compile-time code for +LOOP
     our $compilePlusLoop = sub
    {
        my $gsp - shift;
        my %Dict = %{$gsp->Cfb->Dict};
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $newCreoleWord = @{$gsp->Cfb->Address}[$newRow];
        my @paramField = @{$newCreoleWord->ParamField};
        my $loopAddr = $Dict{"doPlusLoop.IMMEDIATE"}->IndexField;
        my $doLoc = pop(@{$gsp->DataStack});
        push(@paramField, $loopAddr, $doLoc);
        $newCreoleWord->ParamField(\@paramField);
    };   

    # ( start end -- ) Starts off the Do by getting the start and end
     our $doStartDo = sub
    {
        my $gsp = shift;
        my $rLoc = pop(@{$gsp->ReturnStack});
        my $startIndex = pop(@{$gsp->DataStack});
        my $loopEnd = pop(@{$gsp->DataStack});
        my @LoopLabels = @{$gsp->LoopLabels};
        my $li = LoopInfo->new(Label => $LoopLabels[$gsp->LoopLabelPtr], Index => $startIndex, Limit => $loopEnd);
        my @lci = [0, 0, 0];
        $gsp->LoopCurrIndexes(\@lci);
        $gsp->LoopLabelPtr($gsp->LoopLabelPtr + 1);
        push(@{$gsp->ReturnStack}, $li, $rLoc);
    };  

    #  ( inc -- ) Loops back to doDo until the start >= the end and increments with inc
      our $doPlusLoop = sub
    {
        my $gsp = shift;
        my $incVal = pop(@{$gsp->DataStack});
        my @Addresses = @{$gsp->Cfb->Address};
        my $currWord = $Addresses[$gsp->InnerPtr];
        my @paramField = @{$currWord->ParamField};
        my $rLoc = pop(@{$gsp->ReturnStack});
        my $li =  pop(@{$gsp->ReturnStack});
        my $jumpAddr = $paramField[$rLoc->ParamFieldAddr];
        my $loopLimit = $li->Limit;
        my $loopLabel = $li->Label;
        my $currIndex = $li->Index;
        if ($incVal < 0)
        {
            $loopLimit += $incVal;
        }
        else
        {
            $loopLimit -= $incVal;
        }
        if ( ( ($incVal > 0) && $currIndex >= $loopLimit) || ( ($incVal < 0) && $currIndex <= $loopLimit))
        {
            $gsp->ParamFieldPtr($gsp->ParamFieldPtr + 1);
            $rLoc->ParamFieldAddr($gsp->ParamFieldPtr);
            $gsp->LoopLabelPtr( $gsp->LoopLabelPtr - 1);
        }
        else
        {
            $gsp->ParamFieldPtr($jumpAddr);
            $currIndex = $currIndex + $incVal;
            $li->Index($currIndex);
            $rLoc->ParamFieldAddr($gsp->ParamFieldPtr);
            push(@{$gsp->ReturnStack}, $li);
        }

        if ($loopLabel eq "I")
        {
            @{$gsp->LoopCurrIndexes}[0] = $currIndex;
        }
        elsif ($loopLabel eq "J")
        {
            @{$gsp->LoopCurrIndexes}[1] = $currIndex;
        }
        elsif ($loopLabel eq "K")
        {
            @{$gsp->LoopCurrIndexes}[2] = $currIndex;
        }
        else
        {
            print "Error: invalid loop label\n";
        }
        push(@{$gsp->ReturnStack}, $rLoc);      
    };  

    # doLoop is treated as a special case of doPlusLoop
    # ( -- ) Loops back to doDo until the start equals the end 
    our $doLoop = sub
    {
        my $gsp = shift;
        push(@{$gsp->DataStack}, 1);    
        my %Dict = %{$gsp->Cfb->Dict};
        my $codeField = $Dict{"doPlusLoop.IMMEDIATE"}->CodeField;
        &{$codeField}($gsp);
    }; 

    # ( -- index ) Returns the index of I
    our $doIndexI = sub
    {
        my $gsp = shift;
        my @LoopCurrIndexes = @{$gsp->LoopCurrIndexes};
        push(@{$gsp->DataStack}, $LoopCurrIndexes[0]);
    };

    # ( -- index ) Returns the index of J
        our $doIndexJ = sub
    {
        my $gsp = shift;
        my @LoopCurrIndexes = @{$gsp->LoopCurrIndexes};
        push(@{$gsp->DataStack}, $LoopCurrIndexes[1]);
    };

    # ( -- index ) Returns the index of K
    our $doIndexK = sub
    {
        my $gsp = shift;
        my @LoopCurrIndexes = @{$gsp->LoopCurrIndexes};
        push(@{$gsp->DataStack}, $LoopCurrIndexes[2]);
    };

    our $doDoes = sub
    {
        my $gsp = shift;
        my $currWord = @{$gsp->Cfb->Address}[$gsp->InnerPtr];
        my $codeFieldStr = $currWord->CodeFieldStr;
        my $execToken;
        # DOES> has to react differently depending on whether it's inside
        # a colon definition or not.
        if ($codeFieldStr eq "Compiler::doDoes")
        {
            $execToken = $currWord->IndexField;
            # print "Direct execution of doDoes\n";
            $gsp->ParamFieldPtr($currWord->ParamFieldStart);
            push(@{$gsp->DataStack}, $execToken);
            &{$Interpreter::doColon}($gsp);
        }
        else
        {
            $execToken = @{$currWord->ParamField}[$gsp->ParamFieldPtr - 1];
            # print $gsp->ParamFieldPtr . "\n";
            # print "Execution token is $execToken\n";
            &{$Compiler::doExecute}($gsp);
        }
    };

    # 1. Copy the code beyond DOES> into the defining word to the new definition
    # 2. Advance the parameter field pointer past the runtime code that was copied
    #    so it won't be executed.
    # Example: : CONSTANT CREATE , DOES> @ ;
    #            3 CONSTANT THREE
    our $compileDoes = sub
    {
        my $gsp = shift;
        my $rLoc = pop(@{$gsp->ReturnStack});
        my $parentRow = $rLoc->DictAddr;
        my $newRow = scalar(@{$gsp->Cfb->Address}) - 1;
        my $parentCreoleWord = @{$gsp->Cfb->Address}[$parentRow];
        my $childCreoleWord  = @{$gsp->Cfb->Address}[$newRow];
        my $fqNameField = $childCreoleWord->fqNameField;
        my %Dict = %{$gsp->Cfb->Dict};
        my $doesAddr = $Dict{"DOES>.FORTH"}->IndexField;
        my $i = 0;
        my $startCopyPoint;
        $childCreoleWord->CodeField($Compiler::doDoes);
        $childCreoleWord->CodeFieldStr("Compiler::doDoes");
        # Find the location of the does address in the parent definition
        while ($i < scalar(@{$parentCreoleWord->ParamField}))
        {
            if ( @{$parentCreoleWord->ParamField}[$i] == $doesAddr)
            {
                $startCopyPoint = $i + 1;
                last;
            } 
            else
            {
                $i++;
            }  
        }
        
        # Need the definition's address so doDoes can get it easily either when it's being
        # called from the interpreter for from within a compiled definition
        push(@{$childCreoleWord->ParamField}, $newRow);
        $childCreoleWord->ParamFieldStart(scalar(@{$childCreoleWord->ParamField}));
        $i = 0;
        while ($startCopyPoint < scalar(@{$parentCreoleWord->ParamField}))
        {
            push(@{$childCreoleWord->ParamField}, @{$parentCreoleWord->ParamField}[$startCopyPoint]);
            $startCopyPoint++;
            $i++;
        }
        $rLoc->ParamFieldAddr($rLoc->ParamFieldAddr + $i);
        push(@{$gsp->ReturnStack}, $rLoc);
        my @Addresses = @{$gsp->Cfb->Address};
        $Addresses[$newRow] = $childCreoleWord;
        $Dict{$fqNameField} = $childCreoleWord;
        $gsp->Cfb->Address(\@Addresses);
        $gsp->Cfb->Dict(\%Dict);     
    };

     # ( -- ) Jumps unconditionally to the parameter field location next to it and is compiled by ELSE   
    our $doJump = sub
    {
        my $gsp = shift;
        my @Addresses = @{$gsp->Cfb->Address};
        my $currWord = $Addresses[$gsp->InnerPtr];
        my @paramField = @{$currWord->ParamField};
        my $jumpAddr = $paramField[$gsp->ParamFieldPtr + 1];
        my $rLoc = pop(@{$gsp->ReturnStack});
        $gsp->ParamFieldPtr($jumpAddr);
        $rLoc->ParamFieldAddr($gsp->ParamFieldPtr);
        push(@{$gsp->ReturnStack}, $rLoc);
    };    
}

struct ReturnLoc =>
{
    DictAddr => '$',
    ParamFieldAddr => '$'
};

{
    package LogicOps;

    our $Title = "Logical operatives Grouping";

    # ( val1 val2 -- flag ) -1 if equal, 0 otherwise
    our $doEquals = sub
    {
        my $gsp = shift;
        my $val1 = pop(@{$gsp->DataStack});
        my $val2 = pop(@{$gsp->DataStack});       
        if ($val1 == $val2)
        {
            push(@{$gsp->DataStack}, -1);
        }
        else
        {
            push(@{$gsp->DataStack}, 0);          
        }
    };

    # ( val1 val2 -- flag ) 0 if equal, -1 otherwise
    our $doNotEquals = sub
    {
        my $gsp = shift;
        my $val1 = pop(@{$gsp->DataStack});
        my $val2 = pop(@{$gsp->DataStack});       
        if ($val1 == $val2)
        {
            push(@{$gsp->DataStack}, 0);
        }
        else
        {
            push(@{$gsp->DataStack}, -1);          
        }
    };

    # ( val1 val2 -- flag ) -1 if less than, 0 otherwis
    our $doLessThan = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});       
        if ($val1 < $val2)
        {
            push(@{$gsp->DataStack}, -1);
        }
        else
        {
            push(@{$gsp->DataStack}, 0);          
        }
    };     

    # ( val1 val2 -- flag ) -1 if greater than, 0 otherwise
    our $doGreaterThan = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});       
        if ($val1 > $val2)
        {
            push(@{$gsp->DataStack}, -1);
        }
        else
        {
            push(@{$gsp->DataStack}, 0);          
        }
    };     

    # ( val1 val2 -- flag ) -1 if less than or equal to, 0 otherwise
    our $doLessThanOrEqualTo = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});       
        if ($val1 <= $val2)
        {
            push(@{$gsp->DataStack}, -1);
        }
        else
        {
            push(@{$gsp->DataStack}, 0);          
        }
    };  

    # ( val1 val2 -- flag ) -1 if greater than or equal to, 0 otherwise
    our $doGreaterThanOrEqualTo = sub
    {
        my $gsp = shift;
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});       
        if ($val1 >= $val2)
        {
            push(@{$gsp->DataStack}, -1);
        }
        else
        {
            push(@{$gsp->DataStack}, 0);          
        }
    };  

    # ( val -- opval ) -1 if 0, 0 otherwise
    our $doNot = sub
    {
        my $gsp = shift;
        my $val = pop(@{$gsp->DataStack});
        if ($val == 0)
        {
            push(@{$gsp->DataStack}, -1);   
        }
        else
        {
            push(@{$gsp->DataStack}, 0);
        }
    };

    # ( val1 val2 -- flag ) -1 if both arguments are non-zero, 0 otherwise
    our $doAnd = sub
    {
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});  
        if ($val1 != 0 && $val2 != 0)
        {
            push(@{$gsp->DataStack}, -1);               
        }  
        else
        {
            push(@{$gsp->DataStack}, 0);   
        }
    };

    # ( val1 val2 -- flag ) -1 if one or both arguments are non-zero, 0 otherwise
    our $doOr = sub
    {
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});  
        if ($val1 != 0 || $val2 != 0)
        {
            push(@{$gsp->DataStack}, -1);               
        }  
        else
        {
            push(@{$gsp->DataStack}, 0);   
        }
    };

    # ( val1 val2 -- flag ) -1 if one and only one argument is non-zero, 0 otherwise
    our $doXor = sub
    {
        my $val2 = pop(@{$gsp->DataStack});
        my $val1 = pop(@{$gsp->DataStack});  
        if (($val1 != 0 || $val2 != 0) && !($val1 == 0 && $val2 == 0))
        {
            push(@{$gsp->DataStack}, -1);               
        }  
        else
        {
            push(@{$gsp->DataStack}, 0);   
        }
    };       
}
{
    package AppSpec;

    our $Title = "Application-specific grouping";

    # ( -- ) Testing primitive    
    our $doTest = sub
    {
        print "Testing definition : do what you want here\n";
    };
}


struct LoopInfo =>
{
    Label => '$',
    Index => '$',
    Limit => '$'
};

# Colon definitions are built into the PAD area - each new entry
# is a triplet consisting of the word's fully qualified name, its
# dictionary address, and associated compilation action. 
struct CompileInfo =>
{
    FQName => '$',
    Address => '$',
    CompileAction => '$'
};

struct CreoleWord =>
{
    NameField => '$',
    CodeField => '$',
    CodeFieldStr => '$',
    Vocabulary => '$',
    fqNameField => '$',
    CompileActionField => '$',
    HelpField => '$',
    PrevRowLocField => '$',
    RowLocField => '$',
    LinkField => '$',
    IndexField => '$',
    ParamField => '@',
    DataField => '@',
    ParamFieldStart => '$'
};

package main;

my $buildHighLevel = sub
{
    my ($gsp, $code, $help, $cfb) = @_;
    $gsp->InputArea($code);
    my %Dict = %{$cfb->Dict};
    &{$Interpreter::doParseInput}($gsp); 
    &{$Interpreter::doOuter}($gsp);
    my $row = scalar(@{$cfb->Address}) - 1;
    my $cw = pop(@{$cfb->Address});
    $cw->HelpField($help);
 #   print "help field is " . $cw->HelpField . "\n";
 #   print "Index field is " . $cw->IndexField . "\n";
    push(@{$cfb->Address}, $cw);
    $Dict{$cw->fqNameField} = $cw;
    $cfb->Dict(\%Dict);
    @{$gsp->ParsedInput} = ();
    @{$gsp->PADArea} = (); 
    my @vs = ();
    foreach (@{$gsp->VocabStack})
    {
        push (@vs, $_) unless $_ eq "IMMEDIATE";
    }
    $gsp->VocabStack(\@vs);
};

# The onlies
&{$cfb1->buildPrimitive}("ONLY", $Interpreter::doOnly, "Interpreter::doOnly", "ONLY", "EXECUTE","( -- ) Empties the vocabulary stack, then puts ONLY on it", $cfb1);
&{$cfb1->buildPrimitive}("FORTH", $Interpreter::doForth, "Interpreter::doForth", "ONLY", "EXECUTE","( -- ) Puts FORTH on the vocabulary stack", $cfb1);
&{$cfb1->buildPrimitive}("APPSPEC", $Interpreter::doAppSpec, "Interpreter::doAppSpec", "ONLY", "EXECUTE","( -- ) Puts APPSPEC on the vocabulary stack", $cfb1);
&{$cfb1->buildPrimitive}("NOP", $CorePrims::doNOP, "CorePrims::doNOP", "ONLY", "COMPINPF","( -- ) Do-nothing primitive which is surprisingly useful", $cfb1);
&{$cfb1->buildPrimitive}("__#EOL#__", $CorePrims::doNOP, "CorePrims::doNOP", "ONLY", "NOP","( -- ) EOL marker", $cfb1);

# Test words, eval?, and help
&{$cfb1->buildPrimitive}("HELLO", $CorePrims::doHello, "CorePrims::doHello", "FORTH", "COMPINPF","( -- ) prints out Hello World", $cfb1);
&{$cfb1->buildPrimitive}("TULIP", $CorePrims::doTulip, "CorePrims::doTulip", "FORTH", "COMPINPF","( -- ) prints out Tulip", $cfb1);

# Might do EVAL later. It's an evil command. 
#&{$cfb1->buildPrimitive}("EVAL", CorePrims.doEval, "CorePrims.doEval", "FORTH", "COMPINPF","( code -- ) Evaluates raw Perl code", $cfb1);
&{$cfb1->buildPrimitive}("VLIST", $CorePrims::doVList, "CorePrims::doVList", "FORTH", "COMPINPF","( -- ) Lists the dictionary definitions", $cfb1);

# Basic math
&{$cfb1->buildPrimitive}("+", $CorePrims::doPlus, "CorePrims.doPlus", "FORTH", "COMPINPF","( n1 n2 -- sum ) Adds two numbers on the stack", $cfb1);
&{$cfb1->buildPrimitive}("-", $CorePrims::doMinus, "CorePrims.doMinus", "FORTH", "COMPINPF","( n1 n2 -- difference ) Subtracts two numbers on the stack", $cfb1);
&{$cfb1->buildPrimitive}("*", $CorePrims::doMultiply, "CorePrims.doMultiply", "FORTH", "COMPINPF","( n1 n2 -- product ) Multiplies two numbers on the stack", $cfb1);
&{$cfb1->buildPrimitive}("/", $CorePrims::doDivide, "CorePrims.doDivide", "FORTH", "COMPINPF","( n1 n2 -- quotient ) Divides two numbers on the stack", $cfb1);
&{$cfb1->buildPrimitive}("%", $CorePrims::doMod, "CorePrims.doMod", "FORTH", "COMPINPF","( n1 n2 -- remainder ) Returns remainder of division operation", $cfb1);

# Date/time handling
&{$cfb1->buildPrimitive}("TODAY", $CorePrims::doToday, "CorePrims::doToday", "FORTH", "COMPINPF","( -- ) Pops up today's date", $cfb1);
&{$cfb1->buildPrimitive}("NOW", $CorePrims::doNow, "CorePrims::doNow", "FORTH", "COMPINPF","( --  time ) Puts the time on the stack", $cfb1);
#&{$cfb1->buildPrimitive}(">HHMMSS", $CorePrims::doToHoursMinSecs, "CorePrims::doToHoursMinSecs", "FORTH", "COMPINPF","( time -- ) Formats the time", $cfb1);

# Stack manipulation
&{$cfb1->buildPrimitive}("DUP", $CorePrims::doDup, "CorePrims::doDup", "FORTH", "COMPINPF","( val --  val val ) Duplicates the argument on top of the stack", $cfb1);
&{$cfb1->buildPrimitive}("SWAP", $CorePrims::doSwap, "CorePrims::doSwap", "FORTH", "COMPINPF","( val1 val2 -- val2 val1 ) Swaps the positions of the top two stack arguments", $cfb1);
&{$cfb1->buildPrimitive}("ROT", $CorePrims::doRot, "CorePrims::doRot", "FORTH", "COMPINPF","( val1 val2 val3 -- val2 val3 val1 ) Moves the third stack argument to the top", $cfb1);
&{$cfb1->buildPrimitive}("-ROT", $CorePrims::doMinusRot, "CorePrims::doMinusRot", "FORTH", "COMPINPF","( val1 val2 val3 -- val3 val1 val2 ) Moves the top stack argument to the third position", $cfb1);
&{$cfb1->buildPrimitive}("NIP", $CorePrims::doNip, "CorePrims::doNip", "FORTH", "COMPINPF","( val1 val2 -- val2 ) Removes second stack argument", $cfb1);
&{$cfb1->buildPrimitive}("TUCK", $CorePrims::doTuck, "CorePrims::doTuck", "FORTH", "COMPINPF","( val1 val2 -- val2 val1 val2 ) Copies top stack argument under second argument", $cfb1);
&{$cfb1->buildPrimitive}("OVER", $CorePrims::doOver, "CorePrims::doOver", "FORTH", "COMPINPF","( val1 val2 -- val1 val2 val1 ) Copies second stack argument to the top of the stack", $cfb1);
&{$cfb1->buildPrimitive}("DROP", $CorePrims::doDrop, "CorePrims::doDrop", "FORTH", "COMPINPF","( val -- ) Drops the argument at the top of the stack", $cfb1);
&{$cfb1->buildPrimitive}(".", $CorePrims::doDot, "CorePrims::doDot", "FORTH", "COMPINPF","( val -- ) Prints the argument at the top of the stack", $cfb1);
&{$cfb1->buildPrimitive}("DEPTH", $CorePrims::doDepth, "CorePrims::doDepth", "FORTH", "COMPINPF","( -- n ) Returns the stack depth", $cfb1);

# Logical operatives
&{$cfb1->buildPrimitive}("=", $LogicOps::doEquals, "LogicOps::doEquals", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if equal, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("<>", $LogicOps::doNotEquals, "LogicOps::doNotEquals", "FORTH", "COMPINPF","( val1 val2 -- flag ) 0 if equal, -1 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("<", $LogicOps::doLessThan, "LogicOps::doLessThan", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if less than, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}(">", $LogicOps::doGreaterThan, "LogicOps::doGreaterThan", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if greater than, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("<=", $LogicOps::doLessThanOrEquals, "LogicOps::doLessThanOrEquals", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if less than or equal to, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}(">=", $LogicOps::doGreaterThanOrEquals, "LogicOps::doGreaterThanOrEquals", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if greater than or equal to, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("NOT", $LogicOps::doNot, "LogicOps::doNot", "FORTH", "COMPINPF","( val -- opval ) -1 if 0, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("AND", $LogicOps::doAnd, "LogicOps::doAnd", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if both arguments are non-zero, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("OR", $LogicOps::doOr, "LogicOps::doOr", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if one or both arguments are non-zero, 0 otherwise", $cfb1);
&{$cfb1->buildPrimitive}("XOR", $LogicOps::doXor, "LogicOps::doXor", "FORTH", "COMPINPF","( val1 val2 -- flag ) -1 if one and only one argument is non-zero, 0 otherwise", $cfb1);

# Compiler definitions
&{$cfb1->buildPrimitive}(",", $Compiler::doComma, "Compiler::doComma", "FORTH", "COMPINPF","( n --) Compiles value off the TOS into the next parameter field cell", $cfb1);
&{$cfb1->buildPrimitive}("COMPINPF", $Compiler::doComma, "Compiler::doComma", "IMMEDIATE", "COMPINPF","( n --) Does the same thing as , (comma) - given a different name for ease of reading", $cfb1);
&{$cfb1->buildPrimitive}("EXECUTE", $Compiler::doExecute, "Compiler::doExecute", "FORTH", "COMPINPF","( address --) Executes the word corresponding to the address on the stack", $cfb1);
&{$cfb1->buildPrimitive}(":", $Compiler::compileColon, "Compiler::compileColon", "FORTH", "COMPINPF","( -- ) Starts compilation of a colon definition", $cfb1);
&{$cfb1->buildPrimitive}(";", $Compiler::doSemi, "Compiler::doSemi", "IMMEDIATE", "EXECUTE","( -- ) Terminates compilation of a colon definition", $cfb1);
&{$cfb1->buildPrimitive}("COMPLIT", $Compiler::compileLiteral, "Compiler::compileLiteral", "IMMEDIATE", "EXECUTE","( -- ) Compiles doLit and a literal into the dictionary", $cfb1);
&{$cfb1->buildPrimitive}("doLiteral", $Compiler::doLiteral, "Compiler::doLiteral", "IMMEDIATE", "NOP","( -- lit ) Run-time code that pushes a literal onto the stack", $cfb1);
&{$cfb1->buildPrimitive}("HERE", $Compiler::doHere, "Compiler::doHere", "FORTH", "COMPINPF","( -- location ) Returns address of the next available dictionary location", $cfb1);
&{$cfb1->buildPrimitive}("CREATE", $Compiler::doCreate, "Compiler::doCreate", "FORTH", "COMPINPF","CREATE <name>. Adds a named entry into the dictionary", $cfb1);
&{$cfb1->buildPrimitive}("doDoes", $Compiler::doDoes, "Compiler::doDoes", "IMMEDIATE", "COMPINPF", "( address -- ) Run-time code for DOES>", $cfb1);
&{$cfb1->buildPrimitive}("DOES>", $Compiler::compileDoes, "Compiler::compileDoes", "FORTH", "COMPINPF", 
                         "DOES> <list of runtime actions>. When defining word is created, copies code following it into the child definition", $cfb1);
&{$cfb1->buildPrimitive}("@", $Compiler::doFetch, "Compiler::doFetch", "FORTH", "COMPINPF","( addr -- val ) Fetches the value in the param field  at addr", $cfb1);
&{$cfb1->buildPrimitive}("!", $Compiler::doStore, "Compiler::doStore", "FORTH", "COMPINPF","( val addr --) Stores the value in the param field  at addr", $cfb1);
&{$cfb1->buildPrimitive}("DEFINITIONS", $Compiler::doSetCurrentToContext, "Compiler::doSetCurrentToContext", "FORTH",
"COMPINPF","(  -- ). Sets the current (compilation) vocabulary to the context vocabulary (the one on top of the vocabulary stack)", $cfb1);
&{$cfb1->buildPrimitive}("IMMEDIATE", $Compiler::doImmediate, "Compiler::doImmediate", "FORTH", "COMPINPF","( -- ) Flags a word as immediate (so it executes instead of compiling inside a colon definition)", $cfb1);
# Branching compiler definitions
&{$cfb1->buildPrimitive}("IF", $Compiler::compileIf, "Compiler::compileIf", "IMMEDIATE", "EXECUTE","( -- location ) Compile-time code for IF", $cfb1);
&{$cfb1->buildPrimitive}("ELSE", $Compiler::compileElse, "Compiler::compileElse", "IMMEDIATE", "EXECUTE","( -- location ) Compile-time code for ELSE", $cfb1);
&{$cfb1->buildPrimitive}("THEN", $Compiler::compileThen, "Compiler::compileThen", "IMMEDIATE", "EXECUTE","( -- location ) Compile-time code for THEN", $cfb1);
&{$cfb1->buildPrimitive}("0BRANCH", $Compiler::do0Branch, "Compiler::do0Branch", "IMMEDIATE", "NOP","( flag -- ) Run-time code for IF", $cfb1);
&{$cfb1->buildPrimitive}("JUMP", $Compiler::doJump, "Compiler::doJump", "IMMEDIATE", "NOP", 
"( -- ) Jumps unconditionally to the parameter field location next to it and is compiled by ELSE", $cfb1);
&{$cfb1->buildPrimitive}("doElse", $CorePrims::doNOP, "CorePrims::doNOP", "IMMEDIATE", "NOP","( -- ) Run-time code for ELSE", $cfb1);
&{$cfb1->buildPrimitive}("doThen", $CorePrims::doNOP, "CorePrims::doNOP", "IMMEDIATE", "NOP","( -- ) Run-time code for THEN", $cfb1);
&{$cfb1->buildPrimitive}("BEGIN", $Compiler::compileBegin, "Compiler::CompileBegin", "IMMEDIATE", "EXECUTE","( -- beginLoc ) Compile-time code for BEGIN", $cfb1);
&{$cfb1->buildPrimitive}("UNTIL", $Compiler::compileUntil, "Compiler::CompileUntil", "IMMEDIATE", "EXECUTE","( beginLoc -- ) Compile-time code for UNTIL", $cfb1);
&{$cfb1->buildPrimitive}("doBegin", $CorePrims::doNOP, "CorePrims::doNOP", "IMMEDIATE", "NOP","( -- ) Run-time code for BEGIN", $cfb1);
&{$cfb1->buildPrimitive}("DO", $Compiler::compileDo, "Compiler::compileDo", "IMMEDIATE", "EXECUTE","( -- beginLoc ) Compile-time code for DO", $cfb1);
&{$cfb1->buildPrimitive}("LOOP", $Compiler::compileLoop, "Compiler::compileLoop", "IMMEDIATE", "EXECUTE","( -- beginLoc ) Compile-time code for LOOP", $cfb1);
&{$cfb1->buildPrimitive}("+LOOP", $Compiler::compilePlusLoop, "Compiler::compilePlusLoop", "IMMEDIATE", "EXECUTE","( -- beginLoc ) Compile-time code for +LOOP", $cfb1);
&{$cfb1->buildPrimitive}("doStartDo", $Compiler::doStartDo, "Compiler::doStartDo", "IMMEDIATE", "COMPINPF","( start end -- ) Starts off the Do by getting the start and end", $cfb1);
&{$cfb1->buildPrimitive}("doDo", $CorePrims::doNOP, "CorePrims::doNOP", "IMMEDIATE", "COMPINPF","( -- ) Marker for DoLoop to return to", $cfb1);
&{$cfb1->buildPrimitive}("doLoop", $Compiler::doLoop, "Compiler::doLoop", "IMMEDIATE", "COMPINPF","( -- ) Loops back to doDo until the start equals the end", $cfb1);
&{$cfb1->buildPrimitive}("doPlusLoop", $Compiler::doPlusLoop, "Compiler::doPlusLoop", "IMMEDIATE", "COMPINPF","( inc -- ) Loops back to doDo until the start >= the end and increments with inc", $cfb1);
&{$cfb1->buildPrimitive}("I", $Compiler::doIndexI, "Compiler::doIndexI", "FORTH", "COMPINPF","( -- index ) Returns the index of I", $cfb1);
&{$cfb1->buildPrimitive}("J", $Compiler::doIndexJ, "Compiler::doIndexJ", "FORTH", "COMPINPF","( -- index ) Returns the index of J", $cfb1);
&{$cfb1->buildPrimitive}("K", $Compiler::doIndexK, "Compiler::doIndexK", "FORTH", "COMPINPF","( -- index ) Returns the index of K", $cfb1);

# Commenting and list compiler
&{$cfb1->buildPrimitive}("//", $Compiler::doSingleLineCmts, "Compiler::doSingleLineCmts", "FORTH", $gsp->BFC->ExecZeroAction,"( -- ) Single-line comment handling", $cfb1);
&{$cfb1->buildPrimitive}("(", $Compiler::doParenCmts, "Compiler::doParenCmts", "FORTH", $gsp->BFC->ExecZeroAction,"( -- ) Multiline comment handling", $cfb1);
&{$cfb1->buildPrimitive}("{", $Compiler::compileList, "Compiler::compileList", "FORTH", $gsp->BFC->ExecZeroAction,"( -- list ) List compiler", $cfb1);
&{$buildHighLevel}($gsp, ": VARIABLE 0 CREATE , DOES> NOP ;", "Defines a variable", $cfb1);
&{$buildHighLevel}($gsp, ": CONSTANT CREATE , DOES> @ ;", "Defines a constant", $cfb1);

$gsp->CurrentVocab("APPSPEC");
&{$cfb1->buildPrimitive}("TEST", $AppSpec::doTest, "AppSpec::doTest", "FORTH", "COMPINPF","( -- ) Testing primitive ", $cfb1);
&{$buildHighLevel}($gsp, ": HT HELLO TULIP ;", "( -- ) Combination of Hello and Tulip", $cfb1);
&{$buildHighLevel}($gsp, ": HORT IF HELLO ELSE TULIP THEN ; ", "( flag --) Hello or Tulip", $cfb1);
&{$buildHighLevel}($gsp, ": TESTBU BEGIN 1 + DUP 10 > UNTIL ;", "( start --) Tests BEGIN-UNTIL looping", $cfb1);
&{$buildHighLevel}($gsp, ": TESTDL DO HELLO LOOP ;", "( start end -- ) Tests DO-LOOP", $cfb1);

&{$buildHighLevel}($gsp, "55 CONSTANT ABC", "CONSTANT ABC", $cfb1);
&{$buildHighLevel}($gsp, "VARIABLE DEF", "DEF", $cfb1);
&{$buildHighLevel}($gsp, "27 DEF !", "DEF", $cfb1);

#my $cfb2 = clone($cfb1);
$gsp->Cfb($cfb1);

$gsp->InputArea("TEST");
&{$Interpreter::doParseInput}($gsp);
&{$Interpreter::doOuter}($gsp);
@{$gsp->ParsedInput} = ();
$gsp->InputArea("DEF @ .");
&{$Interpreter::doParseInput}($gsp);
&{$Interpreter::doOuter}($gsp);

