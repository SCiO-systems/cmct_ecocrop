library("Recocrop")
library("jsonlite")
library("terra")
library("aws.s3")
library("stringi")

#-------------------------------------------------
handler = function(body, ...){
  tryCatch(
    {
      input_json = fromJSON(txt = body)
      # get the default params for a plant from the 1710 of the database
      x = ecocropPars(input_json$model_data$plant)
      x_params = x$parameters
      # check ecocropPars documentation for more info on them
      
      
      # create an EcoCrop model with previous parameters
      model = ecocrop(x)
    
      # Next, provide environmental data with the staticPredictors and/or dynamicPredictors methods.
      # dynamic variables must have 12 values, one for much month of the year, or multiples of 12 values, to represent multiple years or locations.
      
      # add parameters
      if (length(input_json$model_data$add_parameters)>0){
        for (i in 1:length(input_json$model_data$add_parameters$data)) {
          # create parameter in right format to be added to the model
          y = cbind(input_json$model_data$add_parameters$data[[i]])
          colnames(y) = paste(input_json$model_data$add_parameters$param_name[[i]])
          crop(model) = y
          
        }
      }
      
      # add dynamic predictors
      if (length(input_json$model_data$dynamic_predictors)>0){
        for (i in 1:length(input_json$model_data$dynamic_predictors$data)) {
          # create dynamic predictor in right format to be added to the model
          y = cbind(input_json$model_data$dynamic_predictors$data[[i]])
          colnames(y) = paste(input_json$model_data$dynamic_predictors$pred_name[[i]])
          dynamicPredictors(model) = y
        }
      }
      
      # add static predictors
      if (length(input_json$model_data$static_predictors$pred_name)>0){
        for (i in 1:length(input_json$model_data$static_predictors$data)) {
          # create static predictor in right format to be added to the model
          y = cbind(input_json$model_data$static_predictors$data[[i]])
          colnames(y) = paste(input_json$model_data$static_predictors$pred_name[[i]])
          staticPredictors(model) = y
        }
      }
      
      get_max = input_json$run_extra_stats_params[[1]]
      which_max = input_json$run_extra_stats_params[[2]]
      count_max = input_json$run_extra_stats_params[[3]]
      lim_fact = input_json$run_extra_stats_params[[4]]
      
      work_on_tif = input_json$work_on_tif
      
      # apply control variables
      control(model, get_max=get_max,which_max=which_max,count_max=count_max,lim_fact=lim_fact)
      
      if(!(work_on_tif)){
        # different combinations of model model run
        if (!(get_max | which_max | count_max | lim_fact)){
          # print("case 1")
          # model run model
          # control(model, get_max=get_max,which_max=which_max,count_max=count_max,lim_fact=lim_fact)
          y <- run(model)
          
          x <- matrix(round(y, 1), nrow=2)
          colnames(x) <- month.abb
          rownames(x) <- c("day-1", "day-15")
          x = as.data.frame.table(x)
          colnames(x) <- c("day", "month", "value")
        } else if (lim_fact) {
          # print("case 2")
          # limit factor run model
          # control(model, get_max=get_max,which_max=which_max,count_max=count_max,lim_fact=lim_fact)
          x <- run(model)
          if (length(x)==1){
            names(x) = "lim_fact"
            x = as.data.frame(x)
            rownames(x) <- c()
            colnames(x) <- "lim_fact"
          } else {
            x <- matrix(x, nrow=2)
            colnames(x) <- month.abb
            rownames(x) <- c("day-1", "day-15")
            x = as.data.frame.table(x)
            colnames(x) <- c("day", "month", "value")
            x = list(limit_fact = x)
          }
        } else {
          # print("case 3")
          # run model with other param stats
          # control(model, get_max=get_max,which_max=which_max,count_max=count_max,lim_fact=lim_fact)
          x <- run(model)
          n = c("get_max","which_max","count_max")
          t = c(get_max,which_max,count_max)
          names(x) = n[t]
          
          # ?as.data.frame
          x = as.data.frame(t(x),row.names = NULL)
          # x
          rownames(x) <- c()
          colnames(x) <- n[t]
        }
        
        return(
          list(
            statusCode = 200,
            headers = list("Content-Type" = "application/json"),
            body = toJSON(x)
          )
        )
        
      }else{
        # initialization of the string command
        command = "predict(model"
        for (i in 1:length(input_json$tif_data$tif_path)){
          #get the variable name
          variable_name = input_json$tif_data$tif_variable_name[i]
          #create the local save path          
          local_save_file_path = "/tmp/"
          local_save_file_path = paste0(local_save_file_path,variable_name)
          local_save_file_path = paste0(local_save_file_path,".tif")
          
          # download file from S3
          download.file(url =input_json$tif_data$tif_path[i],local_save_file_path)
          #create the variable from the json parameters
          assign(variable_name,rast(local_save_file_path))
          #extend the string command with each variable
          var_text_for_command = paste0(",",variable_name)
          var_text_for_command = paste0(var_text_for_command,"=")
          var_text_for_command = paste0(var_text_for_command,variable_name)
          command = paste0(command,var_text_for_command)
            }
        
        # check if the user has provided specific arguments for the tif creation and add them to the command string
        # in json enter field "write_options_for_tif_output": "names='output_test_name'"
        # if (!(is.null(input_json$write_options_for_tif_output))) {
        #   command = paste0(command,",wopt=list(")
        #   command = paste0(command,input_json$write_options_for_tif_output)
        #   command = paste0(command,")")  
        # }
        
        command = paste0(command,")")
        #execute the string command
        output_raster = eval(parse(text=command))
        # save the output file to a local tif
        # terra::writeRaster(output_raster, "./Desktop/SCiO_Projects/qvantum/ecocrop-lambda/lambda/output.tif",overwrite=TRUE)
        terra::writeRaster(output_raster, "/tmp/output.tif",overwrite=TRUE)
        
        date_time = gsub(" ","_",format(Sys.time()))
        date_time = gsub(":","_",date_time)
        date_time = gsub("-","_",date_time)
        random_string_ID = do.call(paste0, Map(stri_rand_strings, n=1, length=c(5, 4, 1),
                                               pattern = c('[A-Z]', '[0-9]', '[A-Z]')))
        S3_bucket = "lambda-ecocrop"
        path_to_saved_file_in_S3 = paste0("https://",S3_bucket)  
        
        output_file_save_name = paste0("ecocrop_result_",random_string_ID)
        output_file_save_name = paste(output_file_save_name,date_time,sep="_")
        output_file_save_name = paste0(output_file_save_name,".tif")
        
        path_to_saved_file_in_S3 = paste0(path_to_saved_file_in_S3,".s3.eu-central-1.amazonaws.com/")
        path_to_saved_file_in_S3 = paste0(path_to_saved_file_in_S3,output_file_save_name)

        #upload the file to S3
        put_object(
          file = "/tmp/output.tif",
          object = output_file_save_name, 
          bucket = S3_bucket
        )
        return(
          list(
            statusCode = 200,
            headers = list("Content-Type" = "application/json"),
            body = toJSON(path_to_saved_file_in_S3)
          )
        )
      }
    },
    
    error=function(error_message) {
      
      response = toString(error_message)
      response = substr(response,1,nchar(response)-1)
      return(
        list(
          statusCode = 400,
          headers = list("Content-Type" = "application/json"),
          body = toJSON(response)
        )
      )
    }
  )
      
      
}  
