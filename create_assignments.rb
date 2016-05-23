require 'typhoeus'
require 'csv'
require 'json'

################################# CHANGE THESE VALUES ###########################
access_token = '<your token>'
domain = '<domain>' 			# domain.instructure.com, use domain
env = nil  				# leave blank or nil is pushing to production
csv_file = 'assignment_creation.csv'			# use the full path to the file /Users/XXXXX/Path/To/File.csv
############################## DO NOT CHANGE THESE VALUES #######################

default_headers = {"Authorization" => "Bearer #{access_token}"}
env ? env << "." : env
base_url = "https://#{domain}.#{env}instructure.com"


hydra = Typhoeus::Hydra.new(max_concurrency: 20)

CSV.foreach(csv_file, {headers: true}) do |row|
	#make sure course exists
	api_get_course = Typhoeus::Request.new("https://#{base_url}.instructure.com/api/v1/courses/sis_course_id:#{row['course_id']}",
										  headers: default_headers)

		api_get_course.on_complete do |response|
			if response.code == 200
				assignments_api = Typhoeus::Request.new("#{base_url}/api/v1/courses/sis_course_id:#{row['course_id']}/assignments",
														method: :post,
														headers: default_headers,
														params: {

																'assignment[name]' => row['name'], 
																'assignment[submission_types]' => row['submission_types'], 
																'assignment[notify_of_update]' => row['notify_of_update'], 
																'assignment[points_possible]' => row['points_possible'], 
																'assignment[grading_type]' => row['grading_type'], 
																'assignment[due_at]' => row['due_at'], 
																'assignment[lock_at]' => row['lock_at'], 
																'assignment[unlock_at]' => row['unlock_at'],
																'assignment[description]' => row['description'], 
																'assignment[muted]' => row['muted'], 
																'assignment[published]' => row['published']

															})
				assignments_api.run
				assignments_api.on_complete do |response|

					puts.response


				end
					

				puts "Successfully created assignment in Course: SIS ID #{row['course_id']}"
			else
				puts "Something broken yo"
			end
	
		
	end
	hydra.queue(api_get_course)
end

hydra.run



puts 'Finished processing file.'
