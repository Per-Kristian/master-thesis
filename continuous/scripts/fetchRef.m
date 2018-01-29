function [monoRef, diRef] = fetchRef(user)
%FETCHREF Fetches references for specific user.
%	Returns both Monograph and Digraph references.
%	[m, d] = fetchRef(3) returns mono- and digraph references for user 3.

monoPath = 'Data/filtered/MonographFeatures/';
diPath = 'Data/filtered/DigraphFeatures/';

fromFile = sprintf(strcat(monoPath, 'User_%02d.mat'), user);
if exist(fromFile, 'file') == 2
	monoRef = importdata(fromFile);
end
fromFile = sprintf(strcat(diPath, 'User_%02d.mat'), user);
if exist(fromFile, 'file') == 2
	diRef = importdata(fromFile);
end
end

