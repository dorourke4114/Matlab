function [out] = EfficiencyDataAnalysis(directory)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Title: Data loading and analytics tool for wristed instruments 
% Efficiency data for ER10.
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
%               MoveNDX | Max Jaw Force | Max M1 Torque | Max M3 Torque |
%               Max of MI50E | Min of MI50E | Mean of MI50E | Unit number |
%               Run number
%

%% Variables Declared

 delim1='data';
 %string token delimiter, what the file name should start with
 delim2='R';
 %string token delimiter #2, what the unit number starts with
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Directory search and .xls output
a=dir(directory);
index=0;
out=cell(0,0);
%data sterilization:
for i=1:length(a)-1
    if a(i).isdir == 0
        %make sure it's not a directory entry, won't contain data
        name=a(i).name;
        if strcmpi(name(1:4),delim1)
            %make sure the file begins with the word 'data' (case
            %insensitive) which can be assumed.
            % All data to be analyzed is expected to be titled in this
            % format:
            %
            % 'data###RE###-### E##.csv'
            %
            [~,temp]=strtok(name,delim2);
            %pulls unit name from data file name.
            if ~isempty(temp)
                %only works if it finds R in the name
                index=index+1;
                %this index is how many data files that have been found. used
                %for indexing the output.
                [unit,temp]=strtok(temp);
                %pulls cycle count from file name. Assumes correct format.
                temp=temp(2:end);
                [cycle,~]=strtok(temp,'.');
                data=xlsread([directory,'\',name]);
                newdat=ER10_Efficiency_double(data,name);
                %newdat=num2cell(newdat);
                %put data where it is supposed to go in 'out'
                for y=4*index-3:4*index
                    for x=1:7
                        out{y,x}=newdat(mod(y-1,4)+1,x);
                        %mod used to get the local index number
                        %the out data is now a cell, converted from double
                        %array.
                    end
                    out{y,8}=unit;
                    out{y,9}=cycle;
                    %print unit name and cycle count in summary.
                end
            end
        end
            
    end
end
labels={'Row Labels','Max of Jaw Force (N)','Max of Mtr 1 Trq (Nmm)','Max of Mtr 3 Trq (Nmm)','Max of MI50E','Min of MI50E','Average of MI50E','Serial Number','Run'};
out=[labels;out];

xlswrite([directory,'\EfficiencyDataSummary.xls'],out);

end


%% Helper function %
function out = ER10_Efficiency_double(data,name)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Script: Data loading and analytics bootstrap for Excel data
% Author: Daniel O'Rourke
%
% Description: This script inputs raw Excel file data, runs analytics, and
% produces a summary in a double array.
%
% Input: data
%           an array of data from the input excel file
%
% Output: out
%           an array of the output data in order:
%               MoveNDX | Max Jaw Force | Max M1 Torque | Max M3 Torque |
%               Max of MI50E | Min of MI50E | Mean of MI50E
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Variables

%Columns where data can be found.
%NOTE: xlsread defaults to ignores columns with text data, so column A
%"Suffix" with unit numbers is ignored.

%  Col   Name  Description
%   C     NDX   Move Index, the run number within a test.
%   E     JF    Jaw Force, the measured force
%   M     M0T   Torque for Motor 0 (used to be called 1)
%   N     M1T   Torque for Motor 1 (used to be called 2)
%   O     M2T   Torque for Motor 2 (used to be called 3)
%   P     M3T   Torque for Motor 3 (used to be called 4)

C_NDX = 2;
C_JF  = 4;
C_M0  = 12;
C_M1  = 13;
C_M2  = 14;
C_M3  = 15;


%% Read in data %%%%%%%%%%%%%%%%%
% Make sense of name data

if ~exist('name','var')
    name = 'no file name';
end

%Get ndx var:
%
%
%   C  NDX

NDX = data(:,C_NDX);

% Get serial no.
%
% unit = data[1:1];
%
% [unita,unitb]=strtok(unit,"-");
% unitb=unitb(2:end);
%

%% Sterilize data

%kill the beginning data that may have inaccurate move indexes. Kill unitl
%you see a move index of 0.

NDXindex=1;
while NDX(NDXindex) ~= 0
    NDX(NDXindex) = 0;
    NDXindex = NDXindex + 1;
end

%remove all but move index 1,3,5,7


mask1=NDX==1;
mask2=NDX==3;
mask3=NDX==5;
mask4=NDX==7;
mask=mask1+mask2+mask3+mask4;
mask=mask==1;
numberline=1:length(mask);
loci=numberline(mask);
data=data(loci,:);

% Get remainder of variables
%  Col   Name
%   C     NDX
%   E     JF
%   M     M0T
%   N     M1T
%   O     M2T
%   P     M3T

JF = data(:,C_JF);
NDX = data(:,C_NDX);



%%
ischange = diff(NDX);
ischange(1)=1;
numberline=1:length(NDX);
changes = numberline(ischange ~= 0);
while length(changes) > 4
    if NDX(changes(1)) ~= 1
        changes(1)=[];
    else
            if NDX(changes(end)) ~= 7
                changes(end)=[];
            else
                error(['data does not appear as expected in file: ',name]);
            end
    end
end

%% Isolate individual Moves

out=zeros(length(changes),7);

gap=max(diff(changes));
changes=[changes,changes(end)+gap];

for i=1:length(changes)-1
    
    tJF=data(changes(i):changes(i+1),C_JF);
    tM0=data(changes(i):changes(i+1),C_M0);
    tM1=data(changes(i):changes(i+1),C_M1);
    tM2=data(changes(i):changes(i+1),C_M2);
    tM3=data(changes(i):changes(i+1),C_M3);
    
    out(i,1)=NDX(changes(i)+1);
    %build output Row Label
    out(i,2)=max(tJF);
    %build output max JF
    out(i,3)=max(tM1);
    out(i,4)=max(tM3);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Build MI50E Table %%%%%%%%%%%%%%
% Rolling average of JawForce for 10 data points
%   JFMA = Rolling Average of JawForce
%   
% Estimated Clamp Force
%   ECF = (-M+N+P-O) * 2 pi / 10.16 * 5.1 / 4 / 18.50
% The 18.50 value is based on a lookup table.
% Efficiency := JFMA / ECF
%
% MIE := Efficiency IF MoveNDX = 1,3,5, or 7
%
% MI50E := all data in MIE after the first 100 data points each MoveNDX
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MI5E data now
        big = length(tJF);
        JFMA = zeros(length(tJF),1);
            for j = 1:big
                JFMA(j)=mean(JF(max(j-9,1):j));
            end
        ECF = (+tM1+tM3-tM2-tM0).*2.*pi./10.16.*5.1./4./18.5;

        Efficiency = JFMA ./ ECF;
        MI5E = Efficiency(100:end);
        
        out(i,5)=max(MI5E);
        out(i,6)=min(MI5E);
        out(i,7)=mean(MI5E);
    
end




end

