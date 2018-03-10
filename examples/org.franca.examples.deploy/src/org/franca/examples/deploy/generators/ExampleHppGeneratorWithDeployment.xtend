/*******************************************************************************
 * Copyright (c) 2013 itemis AG (http://www.itemis.de).
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.franca.examples.deploy.generators

import org.franca.core.franca.FAttribute
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FBasicTypeId
import org.franca.deploymodel.core.FDeployedInterface

import org.example.spec.SampleDeploySpec.InterfacePropertyAccessor
import org.example.spec.SampleDeploySpec.Enums.CallSemantics
import org.example.spec.SampleDeploySpec.Enums.Encoding

import static extension org.franca.core.framework.FrancaHelpers.*

/**
 * This is an example code generator for Franca interfaces with
 * attached deployment information. See member function generateMethodDecl()
 * for some examples of how to read deployment information from the
 * input model.
 */
class ExampleHppGeneratorWithDeployment {

	/*
	 * An instance of the InterfacePropertyAccessor for SampleDeploySpec-models
	 * (it has been generated automatically from SampleDeploySpec.fdepl).
	 */
	InterfacePropertyAccessor deploy
	
	/*
	 * This function is called from outside and generates code from a 
	 * Franca interface definition and deployment information attached to it.
	 * The FDeployedInterface instance is a wrapper which is used to 
	 * instantiate a SampleDeploySpecInterfacePropertyAccessor.
	 * This InterfacePropertyAccessor object will be used to read the
	 * deployment information attached to the Franca interface.
	 */
	def generateInterface (FDeployedInterface deployed) {
		deploy = new InterfacePropertyAccessor(deployed)
		generateInterface(deployed.FInterface)	
	} 
	
	/*
	 * This function is the (internal) entry point for generating
	 * code from a Franca interface specification. It uses the basic
	 * FInterface object as starting point; however, during code 
	 * generation it will access the deployment information via the
	 * "deploy" member.
	 */
	def private generateInterface (FInterface api) '''
		#ifndef __C�api.name.toUpperCase�_hpp__
		#define __C�api.name.toUpperCase�_hpp__
		�api.generateHeader�
		
		// include needed user-defined data types
		�FOR t : api.types�
		include "�t.name.toFirstUpper�.hpp"
		�ENDFOR�
		
		class �api.classname�
		{
		public:
			�api.classname� (const char* address);
			
			// getters for attributes
			�FOR a : api.attributes�
			�a.generateAttributeGetter�
			�ENDFOR�

			// methods
			�FOR m : api.methods�
			�m.generateMethodDecl�
			 
			�ENDFOR�
		
		private:
			// attributes
			�FOR a : api.attributes�
			�a.type.generate� m�a.name.toFirstUpper�;�IF deploy.getIsMasked(a)� // read only�ENDIF�
			�ENDFOR�
		};
		
		#endif
	'''

	def private generateAttributeGetter (FAttribute a) {
		val range = a.genRange
		a.type.generate + " " + 
			"get" + a.name.toFirstUpper + "() const;" + 
			(if (range!=null) (" // " + range) else "")
	}

	def private generateHeader (FInterface api) '''
		/**
		 * This is a generated file for interface �api.name�.
		 * Generated by Franca-based example basic generator version 0.9.0.
		 *
		 * NOTE: This code is by far not complete - it is used as an example for
		 *       code generation based on Franca IDL using Xtend (see xtend-lang.org).
		 *
		 * If you want real C++ code generation for Franca, you should consider
		 * the Common API project. See http://projects.genivi.org/commonapi/ .
		 */

		#include <stdio>
		#include "the_framework.hpp"
	'''


	/*
	 * This function uses the PropertyAccessor instance "deploy" in order
	 * to access property values for the given interface. E.g. it uses 
	 * deploy.getCallSemantics() to access the "CallSemantics" property
	 * for FMethods. 
	 */
	def private generateMethodDecl (FMethod it) '''
		�IF deploy.getCallSemantics(it)==CallSemantics::synchronous�
		// this is a synchronous call
		�ELSE�
		// this is an asynchronous call
		�ENDIF�
		�FOR a : inArgs�
			�IF a.type.predefined!=null && a.type.predefined==FBasicTypeId::STRING�
			// encoding of '�a.name�' is �IF deploy.getEncoding(a)==Encoding::utf8�UTF8�ELSE�UNICODE�ENDIF�
			�ENDIF�
		�ENDFOR�
		void �name� (�FOR a : inArgs SEPARATOR ', '��a.type.generate� �a.name��ENDFOR�);
	'''
	

	def private generate (FTypeRef it) {
		if (derived!=null) {
			derived.name
		} else {
			switch (predefined) {
				case FBasicTypeId::INT8   : "Int8"
				case FBasicTypeId::INT16  : "Int16"
				case FBasicTypeId::INT32  : "Int32"
				case FBasicTypeId::UINT8  : "UInt8"
				case FBasicTypeId::UINT16 : "UInt16"
				case FBasicTypeId::UINT32 : "UInt32"
				case FBasicTypeId::STRING : "const String&"
				default                   : "/*" + predefined.toString + "*/"  // TODO
			}
		}		
	}
	
	def private String genRange (FAttribute attr) {
		if (attr.type.isInteger) {
			val a = deploy.getRangeMin(attr)
			val b = deploy.getRangeMax(attr)
			"[" + a + ".." + b + "]"
		} else {
			null
		}
	} 	

	
	// ***********************************************************************************
	// helper functions

	def private getClassname (FInterface api) {
		"C" + api.name + "Interface"
	}

}