classdef DBAccess
	%DBACCESS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		conn
	end
	
	methods
		function obj = DBAccess()
			%DBACCESS Construct an instance of this class
			%   Detailed explanation goes here
			datasource = '***REMOVED***_simpsmd';
			username = '***REMOVED***';
			password = FileIO.getPassword();
			driver = '***REMOVED***';
			url = 'jdbc:mysql://***REMOVED***:3306/***REMOVED***_simpsmd';
			
			obj.conn = database(datasource,username,password,driver,url);
		end
		
		function paramID = insertParams(obj, params)
			%insertParams Inserts a set of parameters into the DB.
			%   Returns the ID of the inserted row.
			colnames = {'rwrdThreshold','width','maxRwrd', 'maxPen', ...
				'singleOccScore', 'missingScore', 'lockout', 'type'};
			tablename = 'params';
			insert(obj.conn,tablename,colnames,params);
			% Get ID of the inserted row.
			query = ('SELECT id from params WHERE ID = @@IDENTITY');
			curs = exec(obj.conn, query);
			curs = fetch(curs);
			paramID = curs.Data;
		end
	end
end

