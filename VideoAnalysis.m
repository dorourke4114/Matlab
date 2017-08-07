function [ out ] = VideoAnalysis ( in )
  
  if nargin < 1
    %Query for directory or file.
    in = input('Please provide file or directory', 's');
  end
  
  %Determine if file or directory
  [a,b]=strtok(in,'.');
  
  if isempty(b)
    %input is a directory
    
  else
    %input is a filename
    
    v = VideoReader(in);
    while hasFrame(v)
        video = readFrame(v);
    end
  
  
  
end