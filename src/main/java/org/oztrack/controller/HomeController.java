package org.oztrack.controller;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.oztrack.app.Constants;
import org.oztrack.data.model.User;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.mvc.Controller;

/**
 * Created by IntelliJ IDEA.
 * User: uqpnewm5
 * Date: 18/05/11
 * Time: 1:26 PM
 * To change this template use File | Settings | File Templates.
 */
public class HomeController implements Controller {

    /**
     * Logger for this class and subclasses
     */
    protected final Log logger = LogFactory.getLog(getClass());

    @Override
    public ModelAndView handleRequest(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse) {

        User currentUser = (User) httpServletRequest.getSession().getAttribute(Constants.CURRENT_USER);

        String modelAndViewName = "home"; //= httpServletRequest.getRequestURI().replace("/oztrack/","").split(";")[0];

        if (httpServletRequest.getRequestURI().contains("about")) {
            modelAndViewName = "about";
        } else if (httpServletRequest.getRequestURI().contains("contact")) {
            modelAndViewName = "contact";
        }

        logger.debug("modelAndViewName: " + modelAndViewName);
        logger.debug("requestUrl: " + httpServletRequest.getRequestURL());

        ModelAndView modelAndView = new ModelAndView(modelAndViewName);
        modelAndView.addObject(Constants.CURRENT_USER, currentUser);
        return modelAndView;

    }

}
