function [out] = LifeDataAnalysis(directory)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Title: Data loading and analytics tool for wristed instruments
% Lifecycle data for ER10.
%
% Author: Daniel O'Rourke
%
% Description: This script accepts input as a string describing a directory
% This script finds any data that looks right in that directory, analyzes
% it, and outputs an array of the analytics data.
%
%
% Input: data
%           a file directory to search in.
%
% Output: out
%           an array of the output data in order:
%               Cycle | Movement | Max of Cmd Yaw (deg) | Max of Cmd Pitch (deg)
%               Cmd Jaw (deg) | Max of Mtr 0 Trq (Nmm) | Max of Mtr 1 Trq (Nmm)
%               Max of Mtr 2 Trq (Nmm) | Max of Mtr 3 Trq (Nmm)
%

%% Variables Declared

delim1='data';
%string token delimiter, what the file name should start with
delim2='R';
%string token delimiter #2, what the unit number starts with

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sterilize input
%
if ~exist('directory','var')
    directory = input(['Where are the files?',newline]);
end


%% Directory search and .xls output
a=dir(directory);
index=0;
out=cell(0,0);
%data sterilization:
for i=1:length(a)
    if a(i).isdir == 0
        %make sure it's not a directory entry, won't contain data
        name=a(i).name;
        disp(['Now processing: ',name]);
        if strcmpi(name(1:4),delim1)
            %make sure the file begins with the word 'data' (case
            %insensitive) which can be assumed.
            % All data to be analyzed is expected to be titled in this
            % format:
            %
            % 'data###RE###-### R##.csv'
            %
            [~,temp]=strtok(name,delim2);
            %pulls unit name from data file name.
            if ~isempty(temp)
                %only works if it finds R (delim2) in the name
                index=index+1;
                %this index is how many data files that have been found. used
                %for indexing the output.
                [unit,temp]=strtok(temp); %#ok<STTOK> String Tokenizer in a
                % loop ok, because text scan is a pain for this task
                %
                % pulls cycle count from file name. Assumes format:
                % unit number is separated by a space, and is the first
                % space in the file name.
                %
                %
                % Using string token instead of textscan, supressed error.
                %
                temp=temp(2:end);
                [cycle,~]=strtok(temp,'.');
                [~,text,raw]=xlsread([directory,'\',name]);
                %Debugger flag checker
                %headers=text(1,:);
                if strcmpi(text{1,1},'FLAG')
                    disp('Flag detected! Press any key to continue');
                    disp(raw(1:3,1:3));
                    pause;
                end
                
                
                %THIS LINE BELOW CALLS DATA ANALYSIS%
                %% RUN SUBFUNCTION
                newdat=Life_analysis(raw,name);
                %%
                %put data where it is supposed to go in 'out'
                [h1,~]=size(out);
                %figure out how big out is before adding data
                [h2,n2]=size(newdat);
                %figure out how much data is being added.
                i1=1;
                %put new data in a new hole in out. This should index
                %outside of the array to print new data.
                for i=h1+1:h1+h2 %#ok<FXSET>
                    %This for loop gets a flag because matlab doesn't like
                    %nested for loops. I suppressed <FXSET>.
                    j1=1;
                    for j=3:n2+2
                        out{i,j}=newdat(i1,j1);
                        j1=j1+1;
                    end
                    out{i,1}=unit;
                    %Add in unit number to all newly added data points.
                    out{i,2}=cycle(2:end);
                    %Add in run number to all newly added data points.
                    i1=i1+1;
                end
            end
        end
    end
end
labels={'Instrument','Run','Cycle','Movement','Max of Cmd Yaw (deg)','Max of Cmd Pitch (deg)','Cmd Jaw (deg)','Max of Mtr 0 Trq (Nmm)','Max of Mtr 1 Trq (Nmm)','Max of Mtr 2 Trq (Nmm)','Max of Mtr 3 Trq (Nmm)'};
out=[labels;out];

%Output data

xlswrite([directory,'\LifeDataSummary.xls'],out);

%Say goodbye and tell user where to find data.

endstring='\LifeDataSummary.xls';
goodbye=sprintf('Analysis completed successfully!\nSummary can be found here:\n%s%s',directory,endstring);
disp(goodbye); %#ok<DSPS> Supressing error because I'm forcing display's hand.

end

%% Helper Function
function [out] = Life_analysis(raw,name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Script: Data loading and analytics bootstrap for Excel lifecycle data
% Author: Daniel O'Rourke
%
% Description: This subscript inputs raw Excel file data, runs analytics, and
% produces a summary in a double array.
%
% Input: data
%           an array of data from the input excel file
%
% Output: out
%           an array of the output data in order:
%               Cycle | Movement | Max of Cmd Yaw (deg) | Max of Cmd Pitch (deg)
%               Cmd Jaw (deg) | Max of Mtr 0 Trq (Nmm) | Max of Mtr 1 Trq (Nmm)
%               Max of Mtr 2 Trq (Nmm) | Max of Mtr 3 Trq (Nmm)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Variables

%The desired move indexes for analysis
WantedNDX=[2,3,4];

%REMEMBER MATLAB STARTS COUNTING AT 1 NOT 0!!!!!!!!!
%INDEX HAS ZEROS SO NDX(Matlab) = NDX(Actual) + 1

builderhelperlow=[2,212,450,712,954,1158,1389,1622,1810,2056,2283,2546,2778,3010,3234,3454,3704,3941,4147,4396,4643];
%IF greather than or equal to low

builderhelperhigh=[208,428,672,940,1151,1378,1615,1804,2027,2278,2538,2770,3001,3226,3434,3676,3923,4129,4368,4620,4858];
%IF less than or equal to high

if size(builderhelperlow) ~= size(builderhelperhigh)
    error('CODE ERROR: Local variable size mismatch');
end


%% Error Handling %%%%%%%%%%%%%%%%%
% Make sense of name data
% This function should only be called as a subfunction, and the inputs can
% be expected to be well determined. These errors should never occur unless
% the file is completely wrong.

if ~exist('raw','var')
    error('Data not found in file %s',name);
end

if ~exist('name','var')
    name = '<FILE NAME NOT FOUND>';
    error('Data format error in file %s',name);
end

%% Column Finder

%Columns where data can be found.
%
% This section reads in headers and finds which column data is located in.
%
% This section was added because of the inconsistent data structure
% reported by the test fixture.

[~,bigness]=size(raw);
loki=1:bigness;

%Find the columns where the headers have this name

C_CYCLE = loki(strcmpi(raw(1,:),'Cycle'));
C_NDX   = loki(strcmpi(raw(1,:),'Move Index'));
C_PITCH = loki(strcmpi(raw(1,:),'Cmd Pitch (deg)'));
C_YAW   = loki(strcmpi(raw(1,:),'Cmd Yaw (deg)'));
C_JAW   = loki(strcmpi(raw(1,:),'Cmd Jaw (deg)'));
C_M0    = loki(strcmpi(raw(1,:),'Mtr 0 Trq (Nmm)'));
C_M1    = loki(strcmpi(raw(1,:),'Mtr 1 Trq (Nmm)'));
C_M2    = loki(strcmpi(raw(1,:),'Mtr 2 Trq (Nmm)'));
C_M3    = loki(strcmpi(raw(1,:),'Mtr 3 Trq (Nmm)'));

C_ALL=[C_CYCLE,C_NDX,C_PITCH,C_YAW,C_JAW,C_M0,C_M1,C_M2,C_M3];

%Check to make sure all of the headers were found correctly

if length(C_ALL) ~= 9
    error('Data format error in file %s \nColumn Header Naming Error ',name);
end

%% Data Scrubber
% Clean the data, because data begins with garbage from the previous cycle.

% Scan for the first time Cycle and Move Index (raw) = 0, then garbage
% collect all above.

cycle = [raw{2:end,C_CYCLE}];
ndx   = [raw{2:end,C_NDX}];

garbagemark1=cycle==0;
garbagemark2=ndx==0;
garbagemark3=and(garbagemark1,garbagemark2);
whereis=1:length(garbagemark3);
garbagepickup=whereis(garbagemark3);

if size(garbagepickup)==1
    raw(2:garbagepickup,:)=[];
    
    %% Column Builder
    % Now that column locations are found, build data structures from each
    % column.
    
    cycle = [raw{2:end,C_CYCLE}];
    ndx   = [raw{2:end,C_NDX}];
    pitch = [raw{2:end,C_PITCH}];
    yaw   = [raw{2:end,C_YAW}];
    jaw   = [raw{2:end,C_JAW}];
    M0    = [raw{2:end,C_M0}];
    M1    = [raw{2:end,C_M1}];
    M2    = [raw{2:end,C_M2}];
    M3    = [raw{2:end,C_M3}];
    
    
    %% NDX Builder
    % The move index column is encoded, so this section builds a ndx
    % translation vector out of the provided local variables builderhelperlow
    % and builderhelperhigh. It creates a zero index, where a value (1 through
    % 21) is places at strategic sections.
    
    NDXhelper=zeros(1,max(ndx)+1);
    
    for i=1:length(builderhelperlow)
        NDXhelper(builderhelperlow(i):builderhelperhigh(i))=i;
    end
    %Local variables section verifies both helpers are same size
    
    ndx=NDXhelper(ndx+1);
    
    data = [cycle',ndx',pitch',yaw',jaw',M0',M1',M2',M3'];
    
    out=[];
    %prepare the output, it will start being written to.
    
    %% Parse data into chunks
    %  Run for however many chunks there are
    
    for i=0:max(cycle)
        %For each cycle, isolate data, and check moves
        maxes=[];
        %Prepare the suboutput
        mask=cycle==i;
        subdata=data(mask,2:end);
        for j=WantedNDX
            %For each move, isolate data and validate.
            mask=subdata(:,1)==j;
            subsubdata=subdata(mask,2:end);
            if max(subdata(:,1)) >= max(WantedNDX)
                %Validate data, is this a complete cycle? Can we find all the
                %move index values we are looking for? If not skip.
                
                %Find the maxes
                newmaxes=max(subsubdata(:,4:end));
                newmode=mode(subsubdata(:,1:3));
                newmaxes=[j,newmode,newmaxes];
                %#ok<*AGROW> % Suppressing the flag for growing arrays because I don't want
                % To preallocate my size, and it takes a fraction of the time
                % Spent my xlsread and xlswrite
                %Add Movement Index value
                maxes=[maxes;newmaxes];
            end
        end
        [biggy,~]=size(maxes);
        cyc=ones(biggy,1).*i;
        maxes=[cyc,maxes];
        %Add in Cycle number
        out=[out;maxes];
    end
else
    out=[];
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% History
% 
%  Version 1.0
%   Initial Release
%   Author: Daniel O'Rourke
%   Date:   25 May 2016
% 
% 
% 
% 
% 
% 
