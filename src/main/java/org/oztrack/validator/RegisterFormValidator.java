package org.oztrack.validator;

import org.springframework.validation.Errors;
import org.springframework.validation.ValidationUtils;
import org.springframework.validation.Validator;

import org.oztrack.data.model.User;

public class RegisterFormValidator implements Validator {

	
	@Override
    public boolean supports(Class clazz) {
        return User.class.isAssignableFrom(clazz);
    }
	
	public void validate(Object obj, Errors errors) {
	      
		//User user = (User) obj;     

		ValidationUtils.rejectIfEmptyOrWhitespace(errors, "username", "error.empty.field", "Please Enter User Name");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "firstName", "error.empty.field", "Please Enter firstName");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "lastName", "error.empty.field", "Please Enter lastName");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "password", "error.empty.field", "Please Enter Password");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "email", "error.empty.field", "Please Enter email");
	
        /*TODO: 
        1. check username not already in use
        2. re-enter password & check field 
        */
        
	}
	
}	