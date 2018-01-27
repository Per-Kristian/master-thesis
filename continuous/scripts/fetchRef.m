function [monoRef, diRef] = fetchRefs(user)
%FETCHREF Fetches references for specific user.
%	Returns both Monograph and Digraph references.
%	[m, d] = fetchRefs(3) returns mono- and digraph references for user 3.

monoPath = '../../../Data/filtered/MonographFeatures/';
diPath = '../../../Data/filtered/DigraphFeatures/';

fromFile = sprintf(strcat(monoPath, 'User_%02d.mat'), user);
monoRef = importdata(fromFile);
fromFile = sprintf(strcat(diPath, 'User_%02d.mat'), user);
diRef = importdata(fromFile);
end

