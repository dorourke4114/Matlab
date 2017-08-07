function [ out ] = corkscrew( height, radius, datapoints , turns)
if nargin == 3
    turns = 1.5;
end
zi=linspace(0,2.*pi,datapoints);
z=height.*cos(zi);
%z1=linspace(0,height,ceil(datapoints./2));
%z2=linspace(height,0,ceil(datapoints./2));
%z=zeros(1,datapoints);
%z(1:length(z1))=z1;
%z(end-length(z2)+1:end)=z2;
i=linspace(0,turns.*4.*pi,datapoints);
x=radius.*sin(i);
y=radius.*cos(i);
out = [x',y',z'];
end