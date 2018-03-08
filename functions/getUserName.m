function name = getUserName(userNumber)
%GETUSERNAME Returns a username in the format "User_XX".
name = sprintf('User_%02d', userNumber);
end

