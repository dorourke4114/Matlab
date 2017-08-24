function [ out ] = VideoAnalysis ( in , varargin )
%% Title Block
% 
% VideoAnalysis.m
%
% Author: Daniel O'Rourke
%
% This function reads in image or video data and finds
% red and green spots, and tracks their movement.
%
% SR-523 orientation and translation error
% SR-522 delay
%
%% Variables

red_limit   = 200;
dark_limit  = 150;

circle_size = [5,35];

frames_to_skip=0;

%% Input Sterilization

  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file:\n', 's');
  end
  
  % Check Varargin
  
  if nargin > 1
      for ins = 1:length(varargin)
          theswitch=varargin{ins};
          switch theswitch
              case 'skip frames'
                  frames_to_skip = varargin{ins+1};
              
              case 'circle size'
                  circle_size = varargin{ins+1};
              
              case 'red limit'
                  red_limit = varargin{ins+1};
              
              case 'dark limit'
                  dark_limit = varargin{ins+1};
                  
              %Add more cases as needed
          end
      end
  end
  
  %Determine if file or directory
  [~,b]=strtok(in,'.');
  
  if isempty(b)
    %input might be a directory
    if isdir(in)
      %input is a directory
      
    else
      %error, invalid directory
      error('Error: Invalid directory or file');
    end
  else
    %input is a filename
    dataout = videoread(in,frames_to_skip,red_limit,dark_limit,circle_size);
  
  end
out = dataout;
end

%% Sub functions

%% Video reader
function out = videoread(in,frames_to_skip,red_limit,dark_limit,circle_size)


    v = VideoReader(in);
    total_frames=ceil(v.Duration.*v.FrameRate./(frames_to_skip+1))-1;
    
    points=cell(total_frames,2);
    orientations=cell(total_frames,1);
    trajectories=cell(total_frames-1,1);
    
    framenumber=0;
    
    
    
    for temp1 = 1:total_frames
        framenumber=framenumber+1;
        fprintf('Processing frame %d of %d\n',framenumber, total_frames);
        %get frame
        for temp2 = 0:frames_to_skip
            if hasFrame(v)
                img = readFrame(v);
            end
        end
        
        
        %% Do the image processing
        
        point = findcirclepoints (img, red_limit, dark_limit, circle_size);
        toomany=strcmpi(point,'TOO MANY POINTS');
        missing=strcmpi(point,'MISSING');
        points(framenumber,1:4)={'MISSING'};
        orientations(framenumber,1)={'MISSING'};
        if toomany
            points(framenumber,1:4)={'TOO MANY POINTS'};
            orientations(framenumber)={'TOO MANY POINTS'};
            trajectories{framenumber}='TOO MANY POINTS';
        else
            if any(~missing)
                %If any points are found
                for ndx = 1:4-sum(missing)
                    points(framenumber,ndx)=point(ndx);
                end
                if any(missing)
                    %if any points are missing

                else
                    %if all 4 points are found

                    %make array of current points
                    center=[point{1};point{2};point{3};point{4}];

                    %find orientation angles
                    distances=diff(center);
                    distances(2,:)=[];
                    orientation=(360./(2.*pi)).*tan(distances(:,1)./distances(:,2));
                    
                    orientations(framenumber)={orientation(1:2)};


                    if framenumber>1
                        %make array of last point
                        lastpoint=points(framenumber-1,:);
                        if any(strcmpi(lastpoint,'MISSING'))
                            %skip traj
                            trajectories{framenumber} = 'MISSING';
                        elseif any(strcmpi(lastpoint,'TOO MANY POINTS'))
                            %skip traj
                            trajectories{framenumber} = 'TOO MANY POINTS';
                        else
                            %Find trajectory
                            movement1=[point{2};lastpoint{2}];
                            movement2=[point{4};lastpoint{4}];
                            move1=diff(movement1);
                            traj1=(360./(2.*pi)).*tan(move1(1)./move1(2));
                            move2=diff(movement2);
                            traj2=(360./(2.*pi)).*tan(move2(1)./move2(2));

                            trajectories{framenumber}=[traj1,traj2];
                        end
                    else

                            trajectories{framenumber} = 'MISSING';

                    end
                end
            end
        end
    end
    out = {points, orientations, trajectories};
end
%% Find Circle Points
function point = findcirclepoints (img, red_limit, dark_limit, circle_size)
% Find circle points 

%Temp crop
img = img(100:end,:,:);

 %split image
        r=img(:,:,1);g=img(:,:,2);b=img(:,:,3);
        %find red
        rmask = g<dark_limit & r>red_limit & b<dark_limit;
        %set red and green to white
        g(rmask)=254;r(rmask)=254;b(rmask)=254;
        %make all not red black
        g(~rmask)=0;r(~rmask)=0;b(~rmask)=0;
        newimg=r./3+g./3+b./3;
        BW=imbinarize(newimg);
        BW=edge(BW,'canny');
        [centers,~,~]=imfindcircles(BW,circle_size);
        if isempty(centers)
          %error, no points found
          point={'MISSING'};
        else
          [a,~]=size(centers);
          switch a
              case 1
              %error only 1 point found
                  point={centers(1,:),'MISSING','MISSING','MISSING'};
              case 2
                  %sort points by x coordinate, sort left to right
                  [~,loci]=sort(centers(:,2));
                  centers=centers(loci,:);
                  
                  
                  point={centers(1,:),centers(2,:),'MISSING','MISSING'};
              case 3
                  %sort points by y coordinate, sort top to bottom
                  [~,loci]=sort(centers(:,1));
                  centers=centers(loci,:);
                  
                  %find which 2 are closest in y coordinate
                  [~,locia]=min(diff(centers(:,1)));
                  
                  %sort the 2 close points by x coordinate, left right
                  [~,locib]=sort(centers(locia:locia+1,2));
                  centers(locia:locia+1,:)=centers(locia+locib,:);
                      
                  point={centers(1,:),centers(2,:),centers(3,:),'MISSING'};
              case 4
                  %sort points by y coordinate, sort top to bottom
                  [~,loci]=sort(centers(:,1));
                  centers=centers(loci,:);
                  %sort pairded points by x coordinate, sort left to right
                  [~,locia]=sort(centers(1:2,2));
                  [~,locib]=sort(centers(3:4,2));
                  centers(1:2,:)=centers(locia,:);
                  centers(3:4,:)=centers(locib+2,:);
                  
                  point={centers(1,:),centers(2,:),centers(3,:),centers(4,:)};
                  %point = [ top 2 points (leftmost, rightmost) ,
                  %         bottom 2 points (leftmost, rightmost) ]
                  
              otherwise
                  point={'TOO MANY POINTS'};
                  
          end
        end

end